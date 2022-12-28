import csv
import random
import numpy

account_types = ['personal', 'for minors', 'saving', 'business']
types_ratio = [0.6, 0.05, 0.3, 0.05]

ibans = []
with open('tmp_iban.csv', encoding="utf8") as csvfile:
    reader = csv.reader(csvfile, delimiter=',')
    [ibans.append(row[0].replace(' ', '')) for row in reader]

tmp_account_names = []
with open('tmp_account_names.csv', encoding="utf8") as csvfile:
    reader = csv.reader(csvfile, delimiter=',')
    for row in reader:
        if len(row):
            tmp_account_names.append(row[0].strip('" '))


def create_account(client):
    accountID = random.choice(ibans)
    ibans.remove(accountID)
    clientID = client
    name = random.choice(tmp_account_names)
    tmp_account_names.remove(name)
    account_type = numpy.random.choice(account_types, p=types_ratio)
    current_balance = 0  # random.randint(0, 3_000_000)
    return [accountID, clientID, name, account_type, current_balance]


accounts_data_output = []
for i in range(1, 251):
    for j in range(numpy.random.choice(numpy.arange(1, 4), p=[0.6, 0.3, 0.1])):
        accounts_data_output.append(create_account(i))

with open('output/accounts.csv', 'w', newline='') as csvfile:
    outwriter = csv.writer(csvfile, delimiter=',')
    outwriter.writerow(['AccountID', 'ClientIDName', 'Name', 'AccountType', 'CurrentBalance'])
    [outwriter.writerow(i) for i in accounts_data_output]

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

with open('output/preferences.csv', 'w', newline='') as csvfile:
    outwriter = csv.writer(csvfile, delimiter=',')
    outwriter.writerow(['ClientID', 'MainAccount', 'AllowPhoneTransfer'])
    [outwriter.writerow(i) for i in preferences_data_output]

print('preferences_data len ', len(preferences_data_output))
# ----------------------------------------------------------CREDIT CARDS

creditcard_numbers = []
with open('tmp_creditcard_numbers.csv', encoding="utf8") as csvfile:
    reader = csv.reader(csvfile, delimiter=',')
    [creditcard_numbers.append(row[0]) for row in reader]


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

with open('output/cards.csv', 'w', newline='') as csvfile:
    outwriter = csv.writer(csvfile, delimiter=',')
    outwriter.writerow(['CardID', 'Account', 'Limit', 'PIN'])
    [outwriter.writerow(i) for i in cards_data_output]

print('cards_data len ', len(cards_data_output))
