#!/usr/bin/env python3
#
# Install dependencies by: 
# 
#    apt install python3-pyside2.qtwidgets python3-pyside2.qtuitools
# 
import sys, os 
from PySide2.QtUiTools import QUiLoader
from PySide2.QtWidgets import QApplication, QMainWindow
from PySide2.QtCore import QFile, QIODevice

# script dir
sdir = os.path.dirname(os.path.realpath(__file__))

if __name__ == "__main__":
    app = QApplication(sys.argv)

    # Load the user inteface directly from .ui file
    ui_file_name = os.path.join(sdir, "gui.ui")
    ui_file = QFile(ui_file_name)
    if not ui_file.open(QIODevice.ReadOnly):
        print("Cannot open {}: {}".format(ui_file_name, ui_file.errorString()))
        sys.exit(-1)
    loader = QUiLoader()
    ui = window = loader.load(ui_file)
    ui_file.close()

    if not window:
        print(loader.errorString())
        sys.exit(-1)
    window.show()

    # Application goes here 
    # ... 

    exit_code = app.exec_()
    # Do anything after the application closed, such as saving the configuration files
    sys.exit(exit_code)
