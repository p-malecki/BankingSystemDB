import csv
import math


def import_csv_data(input_location: str):
    data = []
    with open(input_location, encoding="utf8") as csvfile:
        reader = csv.reader(csvfile, delimiter=',')
        [data.append(row) for row in reader]
    return data


def import_file_data(input_location: str):
    data = []
    with open(input_location, encoding="utf8") as file:
        file = file.readlines()
        [data.append(row.strip()) for row in file]
    return data


def export_csv_data(output_location: str, data: list, header=None):
    if header is None:
        header = []
    with open(output_location, 'w', newline='', encoding="utf8") as csvfile:
        outwriter = csv.writer(csvfile, delimiter=',')
        if header:
            outwriter.writerow(header)
        [outwriter.writerow(i) for i in data]


def export_sql_insert(output_location: str, data: list, tablename, typemask):
    if len(data[0]) != len(typemask):
        print("ERR")
        return
    with open(output_location, 'w', encoding="utf8") as file:
        data_split = [data[i*1000:(i+1)*1000] for i in range(math.ceil(len(data) / 1000))]
        for data in data_split:
            file.writelines(f'\nINSERT INTO [{tablename}] VALUES\n')
            for row in data:
                formated_row = '('
                for cell, m in zip(row, typemask):
                    if m == 0:  # INT
                        formated_row += f"{cell},"
                    elif m == 1:  # STR
                        formated_row += f"'{cell}',"
                    elif m == 2:  # DATE
                        formated_row += f"CONVERT(DATE,'{cell}',105),"
                if row != data[-1]:
                    formated_row = formated_row[:-1] + '),\n'
                else:
                    formated_row = formated_row[:-1] + ')\n'
                file.writelines(formated_row)
