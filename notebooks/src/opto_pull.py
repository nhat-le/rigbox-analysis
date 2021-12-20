#!/Users/minhnhatle/opt/anaconda3/envs/default/bin/python
import log_parser
from datetime import datetime

import numpy as np
import pandas as pd

pd.options.mode.chained_assignment = None
def pull_opto_tbl():
    tbl = log_parser.get_googledb_opto()
    tbl.Animal = [elem[:3].upper() for elem in np.array(tbl.Animal)]

    # Narrow down the opto sessions with f26, f27 and f29
    subtbl = tbl[np.isin(tbl.Animal, ['F26', 'F27', 'F29'])]
    subtbl.Area = [elem.split(' ')[0].lower() for elem in subtbl.Area]
    subtbl.Date = [datetime.strptime(elem, '%m/%d/%y').strftime('%m-%d-%Y') for elem in subtbl.Date]
    optotbl = subtbl.loc[np.isin(subtbl.Area, ['frontal', 'motor', 'visual', 'rsc']),
                         ['Date', 'Animal', 'Area', 'Power', 'opto_voltage', 'ntrials', 'notes']]
    return optotbl

if __name__ == '__main__':
    optotbl = pull_opto_tbl()
    datestr = datetime.now().strftime('%Y-%m-%d_%H-%M-%S')
    fileloc = f'/Users/minhnhatle/Documents/ExternalCode/rigbox_analysis/opto/logs/sessionlog_{datestr}.csv'
    masterfileloc = f'/Users/minhnhatle/Documents/ExternalCode/rigbox_analysis/opto/logs/sessionlog.csv'
    optotbl.to_csv(fileloc)
    optotbl.to_csv(masterfileloc)
    print(f'Opto log saved to {fileloc}')