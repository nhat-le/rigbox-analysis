#!/Users/minhnhatle/opt/anaconda3/envs/default/bin/python

import numpy as np
import gspread
import pandas as pd
import scipy.io
import smartload.smartload as smart
import pickle
import os
from tqdm import tqdm
import datetime
# from google.oauth2.credentials import Credentials


from oauth2client.service_account import ServiceAccountCredentials
from pprint import pprint

DB_PATH = '/Users/minhnhatle/Documents/ExternalCode/rigbox_analysis/notebooks/logs/explogs.pkl'


def get_googledb():
    '''
    Query google sheet and obtain log data from exp record spreadsheet
    :return: a pandas data frame with relatively cleaned data
    '''
    scope = ['https://www.googleapis.com/auth/drive.file',
             "https://www.googleapis.com/auth/drive",
             "https://spreadsheets.google.com/feeds",
             'https://www.googleapis.com/auth/spreadsheets']
    creds = ServiceAccountCredentials.from_json_keyfile_name("/Users/minhnhatle/Documents/ExternalCode"
                                                             "/rigbox_analysis/notebooks/creds/creds.json", scope)
    client = gspread.authorize(creds)
    sheet = client.open("BehaviorOptics Experiments Records").get_worksheet(1)

    data = sheet.get_all_records()

    googledb = pd.DataFrame(data)
    googledb = googledb[googledb['Animal ID'] != '']

    assert (len(googledb.columns) == 17)
    googledb.columns = ['date', 'animal', 'time_start', 'time_end', 'experimenter',
                        'rig', 'stage', 'pupil', 'dropped_frames',
                        'data_extraction', 'ntrials', 'nblocks',
                        'water_earned', 'good_for_analyzing', 'notes',
                        'imaging_power_blue', 'imaging_power_violet']

    # Some data cleaning
    googledb.animal = np.char.lower(np.array(googledb.animal).astype('str'))
    googledb.pupil[googledb.pupil == ''] = 'FALSE'
    googledb['formatted_date'] = pd.DatetimeIndex(googledb.date).strftime('%Y-%m-%d')

    # Check for duplicates
    print('Checking for duplicates..')
    assert(np.sum(googledb.duplicated()) == 0)

    return googledb


def get_googledb_opto():
    '''
    Query google sheet and obtain log data from exp record spreadsheet
    :return: a pandas data frame with relatively cleaned data
    '''
    scope = ['https://www.googleapis.com/auth/drive.file',
             "https://www.googleapis.com/auth/drive",
             "https://spreadsheets.google.com/feeds",
             'https://www.googleapis.com/auth/spreadsheets']
    creds = ServiceAccountCredentials.from_json_keyfile_name("/Users/minhnhatle/Documents/ExternalCode"
                                                             "/rigbox_analysis/notebooks/creds/creds.json", scope)
    client = gspread.authorize(creds)
    sheet = client.open("BehaviorOptics Experiments Records").get_worksheet(2)

    data = sheet.get_all_records()

    googledb = pd.DataFrame(data)
    googledb = googledb[googledb['Animal ID'] != '']

    assert (len(googledb.columns) == 18)
    googledb.columns = ['Date', 'Animal', 'time_start', 'time_end', 'experimenter',
                        'rig', 'stage', 'pupil', 'Power', 'opto_voltage', 'ntrials',
                        'Area', 'opto_blocks',
                        'n_opto_blocks', 'non_opto_blocks', 'water', 'good_for_analyzing',
                        'notes']
    #
    # # Some data cleaning
    # googledb.animal = np.char.lower(np.array(googledb.animal).astype('str'))
    # googledb.pupil[googledb.pupil == ''] = 'FALSE'
    # googledb['formatted_date'] = pd.DatetimeIndex(googledb.date).strftime('%Y-%m-%d')
    #
    # # Check for duplicates
    # print('Checking for duplicates..')
    # assert(np.sum(googledb.duplicated()) == 0)

    return googledb


def get_matlabdb():
    '''
    Load matlab data log
    :return: a pandas frame with cleaned data from all matlab logs
    '''
    # Load matlab data log
    data = smart.loadmat('/Users/minhnhatle/Documents/ExternalCode/rigbox_analysis/notebooks/logs/logdb.mat')
    vals = data['logtable']['table']['data']
    colnames = data['logtable']['columns']

    datadict = {}
    for colname, val in zip(colnames, vals):
        datadict[colname] = val

    matlablog = pd.DataFrame(datadict)
    # Parse the experiment log files to find out trial info etc
    rigboxdir = '/Users/minhnhatle/Dropbox (MIT)/Nhat/Rigbox'
    files = matlablog.value

    print('Parsing MATLAB logs')
    ntrials, nblocks, flags, maxdelays = parse_files_for_trial_info(rigboxdir, files)

    # Clean, merge tables, and save
    matlablog['ntrials'] = ntrials
    matlablog['nblocks'] = nblocks
    matlablog['flags'] = flags
    matlablog['maxdelays'] = maxdelays
    matlablog['formatted_date'] = pd.DatetimeIndex(matlablog.dateStr).strftime('%Y-%m-%d')

    # Check for duplicates
    print('Checking for duplicates..')
    assert(np.sum(matlablog.loc[:, ~matlablog.columns.isin(['comments'])].duplicated()) == 0)

    return matlablog

def merge_old_new(oldtbl, newtbl, exclude=[]):
    '''
    Merge old and new tables and remove duplicates
    :param oldtbl: old pandas table
    :param newtbl: new pandas table
    :param exclude: a list, names of columns to exclude
    :return: merged table, duplicates, n-duplicates if any
    '''
    assert(len(newtbl) >= len(oldtbl))
    merged = pd.concat([oldtbl, newtbl])
    duplicates = merged.loc[:, ~merged.columns.isin(exclude)].duplicated()
    result = merged[~duplicates]
    dups = merged[duplicates]
    assert(len(result) >= len(oldtbl))
    if len(result) > len(oldtbl):
        print('New value added')

    return result, dups


def parse_files_for_trial_info(rootdir, files, verbose=0):
    ntrials = []
    nblocks = []
    maxdelays = []
    flags = []

    for file in tqdm(files, position=0, leave=True):
        date, sessid, animal = file.split('_')
        #     if animal != 'f01':
        #         continue
        # print(rootdir, animal, date, sessid, file)
        path = os.path.join(rootdir, animal, date, sessid, file + '_Block.mat')
        try:
            data = smart.loadmat(path)
        except:
            ntrials.append(np.nan)
            nblocks.append(np.nan)
            maxdelays.append(np.nan)
            flags.append(1)
            if verbose:
                print(f'Warning: failed to load file {file}')
            continue

        if 'expDef' in data['block']:
            exptype = data['block']['expDef'].split('\\')[-1]
        else:
            exptype = data['block']['expType']
        if 'blockWorld' not in exptype:
            ntrials.append(np.nan)
            nblocks.append(np.nan)
            maxdelays.append(np.nan)
            if verbose:
                print(f'Warning: file {file} is of type {exptype}, skipping...')
            flags.append(2)
            continue

        contrasts = data['block']['events']['contrastLeftValues']
        if type(contrasts) is int:
            contrasts = [contrasts]
        if isinstance(data['block']['paramsValues'], dict):
            data['block']['paramsValues'] = [data['block']['paramsValues']]

        if 'paramsValues' not in data['block'] or len(data['block']['paramsValues']) == 0 or \
            'rewardDelay' not in data['block']['paramsValues'][0]:
            ntrials.append(len(contrasts))
            nblocks.append(np.sum(np.diff(contrasts) != 0))
            maxdelays.append(np.nan)
            if verbose:
                print(f'Warning: file {file} does not have delay parameter record...')
            flags.append(3)
        else:
            delays = [elem['rewardDelay'] for elem in data['block']['paramsValues']]
            ntrials.append(len(contrasts))
            nblocks.append(np.sum(np.diff(contrasts) != 0))
            maxdelays.append(max(delays))
            flags.append(0)

    return ntrials, nblocks, flags, maxdelays


if __name__ == '__main__':
    # Process new files
    googledb = get_googledb()
    matlabdb = get_matlabdb()

    # Load the old db
    try:
        file_to_load = open(DB_PATH, "rb")
        data = pickle.load(file_to_load)
        file_to_load.close()
        matlabdb_old, googledb_old = data['matlabdb'], data['googledb']

        # Merge and save
        googledb_merged, googledups = merge_old_new(googledb_old, googledb)
        matlabdb_merged, matlabdups = merge_old_new(matlabdb_old, matlabdb, ['comments'])

        # Print info
        print(f'Google db: {len(googledb_old)} entries in old db, {len(googledb_merged)} entries in new db')
        print(f'MATLAB db: {len(matlabdb_old)} entries in old db, {len(matlabdb_merged)} entries in new db')

    except FileNotFoundError:
        print('Warning: db.pkl file not found, creating new file...')
        googledb_merged, matlabdb_merged = googledb, matlabdb


    datestr = datetime.datetime.now().strftime('%Y-%m-%d_%H-%M-%S')
    file_to_store = open(DB_PATH, "wb")
    pickle.dump({'googledb': googledb_merged, 'matlabdb': matlabdb_merged, 'last_updated': datestr}, file_to_store)
    file_to_store.close()

    print('Database updated')
