import csv
import random
import time
import numpy
import bank_data_import_export


# dates

# https://stackoverflow.com/questions/553303/generate-a-random-date-between-two-other-dates
def str_time_prop(start, end, time_format, prop):
    """Get a time at a proportion of a range of two formatted times.

    start and end should be strings specifying times formatted in the
    given format (strftime-style), giving an interval [start, end].
    prop specifies how a proportion of the interval to be taken after
    start.  The returned time will be in the specified format.
    """

    stime = time.mktime(time.strptime(start, time_format))
    etime = time.mktime(time.strptime(end, time_format))

    ptime = stime + prop * (etime - stime)

    return time.strftime(time_format, time.localtime(ptime))


def random_date(start, end):
    return str_time_prop(start, end, '%d-%m-%Y', random.random())


def date_cmp(d1: str, d2: str) -> bool:
    time_format = '%d-%m-%Y'
    d1_time = time.mktime(time.strptime(d1, time_format))
    d2_time = time.mktime(time.strptime(d2, time_format))
    return d1_time <= d2_time


clients = bank_data_import_export.import_csv_data('data/clients.csv')
preferences = bank_data_import_export.import_csv_data('output/preferences.csv')
accounts = bank_data_import_export.import_csv_data('output/accounts.csv')
cards = bank_data_import_export.import_csv_data('output/cards.csv')
accountTypes = bank_data_import_export.import_csv_data('data/accountTypes.csv')
transactionCategories = bank_data_import_export.import_csv_data('data/transactionCategories.csv')
ATMs = bank_data_import_export.import_csv_data('data/ATMs.csv')
ATMsMalfunctions = bank_data_import_export.import_csv_data('data/ATMsMalfunctions.csv')
departments = bank_data_import_export.import_csv_data('data/departments.csv')
employees = bank_data_import_export.import_csv_data('data/employees.csv')

accounts_dict = {accounts[i][0]: accounts[i][1:] for i in range(1, len(accounts))}

# output declarations
Withdraws_data_output = []
Deposits_data_output = []
Transfers_data_output = []
StandingOrders_data_output = []
PhoneTransfers_data_output = []
Transactions_data_output = []
accounts_end = []  # after all operations

objects = bank_data_import_export.import_file_data('data/objects.txt')
verbs = bank_data_import_export.import_file_data('data/verbs.txt')
operationID = 0


def create_phone_transfer(account):
    global operationID
    amt = random.randint(10, 500)
    title = random.choice(objects)
    sender = account[0]
    while True:
        receiver = random.choice(clients[1:])
        if preferences[int(receiver[0])][2] == '1':
            break
    phoneReceiver = receiver[5]
    receiverAccount = accounts_dict[preferences[int(receiver[0])][1]]
    startDate = account[5] if date_cmp(receiverAccount[4], account[5]) else receiverAccount[4]
    if account[6] == 'NONE' and receiverAccount[5] == 'NONE':
        endDate = '15-1-2023'
    elif account[6] == 'NONE' or receiverAccount[5] == 'NONE':
        endDate = account[6] if receiverAccount[5] == 'NONE' else receiverAccount[5]
    elif date_cmp(receiverAccount[5], account[6]):
        endDate = receiverAccount[5]
    else:
        endDate = account[6]
    date = random_date(startDate, endDate)
    category = random.randint(1, 19)
    operationID += 1
    return [operationID, sender, phoneReceiver.replace(" ", ''), amt, title, date, category]


for account in accounts[1:]:
    for i in range(numpy.random.choice(numpy.arange(0, 6), p=[0.1, 0.1, 0.2, 0.3, 0.2, 0.1])):
        PhoneTransfers_data_output.append(create_phone_transfer(account))
print(len(PhoneTransfers_data_output))

# GENERATE
# bank_data_import_export.export_csv_data('output/phoneTransfers.csv', PhoneTransfers_data_output,
#                 ['TransferID', 'Sender', 'PhoneReceiver', 'Amount', 'Title', 'Date', 'Category'])
# bank_data_import_export.export_sql_insert('output/sql_insertions2.sql', PhoneTransfers_data_output, 'PhoneTransfers', [0, 1, 1, 0, 1, 2, 0])
