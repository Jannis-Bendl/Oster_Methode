### Read SymLinks
import os
import pandas as pd

def path_symlink(path):
    if (os.path.isfile("input.txt")):
        input_symlinks = pd.read_csv("input.txt",sep="|")
        input_symlinks.columns = ["Destination","Source"]
        row_start = input_symlinks[input_symlinks['Destination'].str.contains("# Destination")].index
        
        row_start = pd.to_numeric(row_start[0]) + 1
        input_symlinks = input_symlinks.loc[row_start:input_symlinks.shape[0]]
        input_symlinks['Destination'] = "input/"+input_symlinks['Destination'].str.strip()
        input_symlinks['Source'] = input_symlinks['Source'].str.replace("\\{root\\}","..").str.strip()

    path_out = input_symlinks.loc[input_symlinks['Destination'] == path,'Source']
    path_out = path_out[path_out.index[0]]
    return path_out