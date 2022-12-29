import csv
import random
import time
from datetime import datetime
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


def days_range(d1: str, d2: str) -> int:
    date_format = '%d-%m-%Y'
    a = datetime.strptime(d1, date_format)
    b = datetime.strptime(d2, date_format)
    return (b - a).days


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

# --------------------------------------------------------------------------phone_transfers
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
# bank_data_import_export.export_sql_insert('output/sql_insertions2.sql', PhoneTransfers_data_output, 'PhoneTransfers',
#                                           [0, 1, 1, 0, 1, 2, 0])

# --------------------------------------------------------------------------StandingOrders
operationID = 0
service_list = ['Software services', 'Training services', 'Event planning services', 'Consulting services',
                'Marketing services', 'Waste management services', 'Construction services', 'Legal services',
                'Health and wellness services', 'Insurance services', 'Security services', 'Travel services',
                'Finance services', 'Delivery services']


def create_standing_orders(account):
    global operationID

    amt = random.randint(10, 500)
    title = random.choice(service_list)
    sender = account[0]
    while True:
        while True:
            receiver = random.choice(accounts[1:])
            if sender != receiver[0]:
                break
        minDate = account[5] if date_cmp(receiver[5], account[5]) else receiver[5]
        if account[6] == 'NONE' and receiver[6] == 'NONE':
            maxDate = '15-1-2023'
        elif account[6] == 'NONE' or receiver[6] == 'NONE':
            maxDate = account[6] if receiver[6] == 'NONE' else receiver[6]
        elif date_cmp(receiver[6], account[6]):
            maxDate = receiver[6]
        else:
            maxDate = account[6]
        while True:
            StartDate = random_date(minDate, maxDate)
            EndDate = random_date(minDate, maxDate)
            if date_cmp(StartDate, EndDate):
                break
        if days_range(StartDate, EndDate) > 30:
            break
    Frequency = days_range(StartDate, EndDate) // 30
    # print('days ', days_range(StartDate, EndDate), Frequency)
    operationID += 1
    return [operationID, sender, receiver[0], amt, title, Frequency, StartDate, EndDate]


for account in accounts[1:]:
    for i in range(numpy.random.choice(numpy.arange(0, 5), p=[0.1, 0.2, 0.3, 0.3, 0.1])):
        StandingOrders_data_output.append(create_standing_orders(account))
        print(StandingOrders_data_output[-1])
print(len(StandingOrders_data_output))

# GENERATE
bank_data_import_export.export_csv_data('output/standingOrders.csv', StandingOrders_data_output,
                                        ['StandingOrderID', 'Sender', 'Receiver', 'Amount', 'Title', 'Frequency',
                                         'StartDate', 'EndDate'])
bank_data_import_export.export_sql_insert('output/sql_insertions3.sql', StandingOrders_data_output, 'StandingOrders',
                                          [0, 1, 1, 0, 1, 0, 2, 2])
