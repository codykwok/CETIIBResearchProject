import serial
import pandas as pd
import numpy as np
import msvcrt
import sys
import time
import pyqtgraph as pg
from pyqtgraph.Qt import QtGui, QtCore

class FoodProbe(object):
    '''Class for a matched pair of PEEK food probes'''
    def __init__(self, length, widths, TCs):
        tc_k = 19.5
        tc_area = np.pi*0.0001**2/4
        tc_htc = 19.5 / length*tc_area

        peek_k = 0.25
        peek_areas = [np.pi*width**2/4 - np.pi*0.0011**2/4 for width in widths]
        peek_htcs = [peek_k/length*peek_area for peek_area in peek_areas]

        self.htcs = [peek_htc+tc_htc for peek_htc in peek_htcs]
        self.length = length
        self.tcs = TCs

    def calc_food_temp(self, temps):
        if temps[0] == temps[1] and temps[2] == temps[3]:
            return temps[0]
        else:
            food_temp = (temps[0]*temps[2]*self.htcs[0]-temps[2]*temps[1]*self.htcs[0]-temps[0]*temps[2]*self.htcs[1]+temps[0]*temps[3]*self.htcs[1])/\
            (temps[0]*self.htcs[0]-temps[1]*self.htcs[0]-temps[2]*self.htcs[1]+temps[3]*self.htcs[1])
            if food_temp>250 or food_temp<-18:
                return float("NaN")
            else:
                return food_temp
                

class PlotWindow(pg.PlotWidget):
    ''' Class to display and update a single plotting window'''
    def __init__(self, plot_vars):
        self.vars = plot_vars # tuple of plotted variables
        self.win = pg.GraphicsWindow() # graphics window
        self.canvas = self.win.addPlot() # plotting canvas
        self.canvas.addLegend()
        self.curves = {} # dictionary stores plot curves
        self.labels = {}
        for i in range(len(self.vars)): # for each variable add a curve
            # this sets the curves color etc 
            #print(self.vars[i])
            pen_params = pg.mkPen(pg.intColor(i, hues=len(self.vars), 
                       values=1, maxValue=255, minValue=150,
                       maxHue=360, minHue=0, sat=255, alpha=255), 
                       width=2)
            self.labels[self.vars[i]] = pg.LabelItem(justify='right')
            self.labels[self.vars[i]].setText(self.vars[i])
            self.labels[self.vars[i]].setAttr('color', pg.intColor(i, hues=len(self.vars), 
                       values=1, maxValue=255, minValue=150,
                       maxHue=360, minHue=0, sat=255, alpha=255)) 
            self.win.addItem(self.labels[self.vars[i]])
            self.curves[self.vars[i]] = self.canvas.plot(pen=pen_params, name=self.vars[i])

    def check_vars(self, plot_var):
        '''function checks if given variable is plotted by this window'''
        if plot_var in self.vars:
            return True
        else:
            return False
    
    def update(self, plot_var, values):
        '''function alters plotted data and updates the plot window'''
        #print(values)
        self.curves[plot_var].setData(values[1], values[0])
        try:
            self.labels[plot_var].setText(round(values[0][-1],1))
        except IndexError:
            return

class LoggedData(object):
    '''Class to contain, sort and process data from the datalogger'''
    def __init__(self,n_temp,n_power, probes):
        self.n_temp = n_temp
        self.n_power = n_power
        self.n_food = len(probes)
        self.probes = probes
        self.reset()

    def reset(self):
        self.stored_data = {}
        for i in range(self.n_temp):
            self.stored_data["T"+str(i)] = []
            self.stored_data["T"+str(i)+" time"] = []
        for i in range(self.n_power):
            self.stored_data["P"+str(i)] = [0]
            self.stored_data["P"+str(i)+" time"] = [float("NaN")]
        for i in range(self.n_food):
            self.stored_data["F"+str(i)] = []
            self.stored_data["F"+str(i)+" time"] = []

    def log(self,row):
        '''Processes one row of data from the datalogger'''
        try:
            row = str(row)[2:-5] #remove leading and ending characters (b/ and /n/r)
            split_row = row.split(':')
            for packet in split_row:
                parts = packet.split(';')
                if len(parts) == 3:
                    try:
                        if parts[0][0]=='P': # If power data store cumulatively
                            prev_value = self.stored_data[parts[0]][-1]
                            self.stored_data[parts[0]].append(float(parts[2])/1000+prev_value)
                        else:
                            self.stored_data[parts[0]].append(float(parts[2]))
                        self.stored_data[parts[0]+' time'].append(time.time()-start)
                    except KeyError: # catch misnamed variables
                        print("NameError: ", parts[0])
                        return       
        except TypeError: # catch non-lists in 'split' functions
            print("TypeError: ", row)
            return
    
    def probe_calculation(self):
        i=0
        for probe in self.probes:
            temps = []
            for tc  in probe.tcs:
                try:
                    temps.append(self.fetch(tc)[0][-1])
                except IndexError:
                    return
            food_temp = probe.calc_food_temp(temps)
            self.stored_data["F"+str(i)].append(food_temp)
            self.stored_data["F"+str(i)+" time"].append(time.time()) 
            i=i+1


    def variable_list(self):
        return self.stored_data.keys()

    def fetch(self,variable):
        '''Returns time and value data for one variable'''  
        try:
            #print("fetch ",variable)
            return self.stored_data[variable], self.stored_data[variable+' time']
        except NameError:
            print("NameError: ", variable," ", variable+' time')
            return 0,0 
    
    def writecsv(self):
        '''Write data stored in datapoints to csv and purge datapoints'''
        columns = []
        for key in self.stored_data.keys():
            columns.append(pd.Series(self.stored_data[key], name=key))        
        write_format = pd.concat(columns, axis=1)
        write_format = write_format.reindex(sorted(write_format.columns), axis=1)
        fileTime = time.strftime("%b %d %Y %H_%M_%S", time.gmtime())
        write_format.to_csv("Data"+fileTime+".csv")

class Console(object):
    '''Class handles console inputs for the commandline interface'''
    def __init__(self):
        self.buffer = ""

    def check_input(self):
        '''Read input from command line and react accordingly'''
        if msvcrt.kbhit():
            key = str(msvcrt.getch()).split("'")[1]
            if key == str("\\r"):
                command = self.buffer
                self.buffer = ''
                return command
            else:
                print(key,end="")
                sys.stdout.flush() 
                self.buffer = self.buffer+key
                return False
        else:
            return False
    

class UI(object):
    '''Class runs logging and plotting'''
    def __init__(self, plots, port, probes):
        try:
            self.serial_port = serial.Serial(port, 57600, timeout=1)
        except IOError:
            print("Serial port could not be opened")
            exit()

        self.console = Console()
        self.update_timer = time.time()
        self.data = LoggedData(32, 3, probes)
        #print(self.data.variable_list())
        self.plots = []
        for plot_list in plots:
            self.add_plot(plot_list)
        self.run_command('help')

    def add_plot(self, plot_list):
        '''Create a new plot window'''
        self.plots.append(PlotWindow(plot_list))
    
    def run_command(self, command):
        '''Acts on commands typed into the console'''
        if command == False:
            return

        command = command.upper()
        if command[:4] == 'QUIT':
            print('')
            print('Writing csv and closing...')
            self.data.writecsv()
            exit()
        if command[:5] == 'WRITE':
            print('')
            print('Writing csv file...')
            self.data.writecsv() 
            return
        if command[:5] == "FLUSH":
            print('')
            print('Writing csv file and flushing stored data...')
            self.data.writecsv()
            self.data.reset()
            return
        if command[:4] == 'PLOT':
            print('')
            print('adding plot...')
            plot_string = command[4:]
            new_plots = plot_string.split(",")
            new_plots = [element.replace(" ","") for element in new_plots]
            for new_variable in new_plots:
                if not new_variable in self.data.variable_list():
                    print("Invalid variable:"+new_variable)
                    return
            self.plots.append(PlotWindow(new_plots))
            return
        if command[:4] == "HELP":
            print("""Options:
            Write: Save cached data in .csv file, but keep data in RAM
            Flush: Write csv and remove data from RAM
            Quit: Write, then exit the program 
            Plot: Open a new plot window, separate variables with a comma (eg: 'plot T1, T4, T5')
            """)
        else:
            print('')
            print("Invalid command key: "+command)

    def run(self):
        '''Function runs the logging script'''
        self.serial_port.reset_input_buffer()
        while True:
            APP.processEvents()
            self.run_command(self.console.check_input())
            if self.serial_port.inWaiting():
                line = self.serial_port.readline()
                self.data.log(line)
            else:
                if time.time()-self.update_timer > 1:
                    self.update_timer = time.time()
                    self.data.probe_calculation()
                    for variable in self.data.variable_list():
                        for plot in self.plots:
                            if plot.check_vars(variable):
                                plot.update(variable,self.data.fetch(variable))
                            else:
                                continue
# No longer need foodprobe objects

#probe1 = FoodProbe(0.008, [0.002, 0.004], ['T12', 'T13', 'T14', 'T15'])
#probe2 = FoodProbe(0.012, [0.002, 0.004], ['T28', 'T29', 'T30', 'T31'])

plots = [['T0','T1','T2','T3','T4','T5','T6','T7','T8','T9','T10','T11','T12','T13','T14','T15','T16','T17','T18','T19','T20','T21','T22','T23','T24','T25','T26','T27','T28','T29','T30','T31']]

start = time.time()
APP = QtGui.QApplication([])
ui = UI(plots, "COM4", probes=[])
ui.run()