import csv
import random
import time
import numpy
import bank_data_import_export


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


# ----------------------------------------------------------ACCOUNTS
account_types = ['personal', 'for minors', 'saving', 'business']
types_ratio = [0.6, 0.05, 0.3, 0.05]

ibans = bank_data_import_export.import_csv_data('tmp_iban.csv')
ibans = [row[0].replace(' ', '') for row in ibans]

tmp_account_names = []
with open('tmp_account_names.csv', encoding="utf8") as csvfile:
    reader = csv.reader(csvfile, delimiter=',')
    for row in reader:
        if len(row):
            tmp_account_names.append(row[0].strip('" ').replace("'", ''))


def create_account(client):
    accountID = random.choice(ibans)
    ibans.remove(accountID)
    clientID = client
    name = random.choice(tmp_account_names)
    tmp_account_names.remove(name)
    account_type = numpy.random.choice([1, 2, 3, 4], p=types_ratio)
    current_balance = 0  # random.randint(0, 3_000_000)
    StartDate = random_date('1-01-2021', '1-06-2022')
    EndDate = numpy.random.choice([random_date(StartDate, '1-12-2022'), 'NONE'], p=[0.2, 0.8])
    return [accountID, clientID, name, account_type, current_balance, StartDate, EndDate]


accounts_data_output = []
for i in range(1, 251):
    for j in range(numpy.random.choice(numpy.arange(1, 4), p=[0.6, 0.3, 0.1])):
        accounts_data_output.append(create_account(i))

bank_data_import_export.export_csv_data('output/accounts.csv', accounts_data_output,
                                        ['AccountID', 'ClientID', 'Name', 'AccountType', 'CurrentBalance'])
print('accounts_data len ', len(accounts_data_output))
# ----------------------------------------------------------PREFERENCES

preferences_data_output = []
for clientID in range(1, 251):
    accounts = []
    for j in accounts_data_output:
        if j[1] == clientID:
            accounts.append(j[0])
    main_account = random.choice(accounts)
    agreement = numpy.random.choice([0, 1], p=[0.15, 0.85])
    preferences_data_output.append([clientID, main_account, agreement])

bank_data_import_export.export_csv_data('output/preferences.csv', preferences_data_output,
                                        ['ClientID', 'MainAccount', 'AllowPhoneTransfer'])
print('preferences_data len ', len(preferences_data_output))
# ----------------------------------------------------------CREDIT CARDS

creditcard_numbers = bank_data_import_export.import_csv_data('tmp_creditcard_numbers.csv')
creditcard_numbers = [row[0] for row in creditcard_numbers]


def create_card(accountID, balance):
    cardID = random.choice(creditcard_numbers)
    creditcard_numbers.remove(cardID)
    limit = random.randint(0, balance)
    pin = ''.join([str(random.randint(0, 9)) for i in range(4)])
    return [cardID, accountID, limit, pin]


cards_data_output = []
for account in accounts_data_output:
    if account[3] != 'saving':
        for j in range(numpy.random.choice(numpy.arange(1, 5), p=[0.7, 0.2, 0.075, 0.025])):
            cards_data_output.append(create_card(account[0], account[4]))

bank_data_import_export.export_csv_data('output/cards.csv', cards_data_output, ['CardID', 'Account', 'Limit', 'PIN'])
print('cards_data len ', len(cards_data_output))
