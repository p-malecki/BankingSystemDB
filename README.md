# Simplified Banking Management System

A database project created during Computer Science bachelor's degree at Jagiellonian University.


## Project description:
###### [full version in file "bank_project_description.pdf"](https://github.com/p-malecki/BankingSystemDB/blob/main/bank_project_description.pdf) 


### CEL ORAZ ZAŁOŻENIA PROJEKTU

Celem naszego projektu było utworzenie bazy danych systemu bankowego obsługiwanej przez aplikację 
kliencką dla klienta banku i pracownika nadzorującego bazę tj. administratora bazy. Stworzono
i zaimplementowano szereg funkcjonalności służących do jej sprawnego zarządzania z obu perspektyw. 
Schematyczność w obsługiwaniu różnych typów kont, klientów, bankomatów i oddziałów pozwala
na proste dodawanie nowego podmiotu do bazy, spełniając założenia dla jego typu.

#### Struktura banku

System działa dla wyimaginowanego międzynarodowego banku, posiadającego oddziały w różnych 
krajach. Oddziałom podlegają bankomaty, w których można przeprowadzać wpłaty i wypłaty. Klienci 
mają ukończone co najmniej 16 lat. Mogą posiadać wiele kont, a każde z nich może posiadać kilka kart 
kredytowych (w zależności od typu konta). Dozwolone są przelewy na własne konta. Karty posiadają 
limity tj. maksymalną sumę, którą można jednorazowo wydać.

#### Ograniczenia przyjęte przy projektowaniu

Zakładamy uproszczony system banku, w którym operacje mają naśladować ich główne zamierzenie 
z pominięciem szczegółów technicznych, wymagań wobec klientów (np. zdolność kredytowa) 
i ze znacznym uproszczeniem zabezpieczeń (dowolne hasło 20 znaków), które w prawdziwym systemie 
bankowym stanowią kluczowy element. Pominiętym zostało również weryfikację poprawności danych 
do przelewów z kontami zewnętrznymi spoza naszego systemu bankowego.

#### Możliwości

Aplikacja dla klienta pozwala na zarządzanie kontem bankowym, wykonywanie prostych przelewów oraz
wpłaty i wypłaty w bankomatach lokalnych oddziałów. Możliwości przepływu pieniędzy zostały 
wzbogacone o przelewy na numer telefonu, przelewy na własne konto oraz zlecenie stałych przelewów.
Klient z kontem typu różnym od konta dla młodzieży może również pobrać pożyczkę. Oprócz tego istnieje 
możliwość zmiany hasła konta lub PINu dla karty kredytowej. Wprowadziliśmy opcję sprawdzania historii 
konta, z uwzględnieniem uproszczonych filtrów wyszukiwania.
Ze strony administratora bazy istnieje szereg operacji służących zarządzaniem klientami oraz lokalnymi 
oddziałami banku. Przewidziano funkcjonalności takie jak dodawanie nowego pracownika, oddziału oraz 
bankomatu. Można utworzyć nowy typ konta i kategorię transakcji. Dodatkowo został 
zaimplementowany system pożyczek. Pracownik nadzorujący bazę może utworzyć bądź zamknąć konto 
dla nowego lub obecnego klienta banku, monitorować stan wszystkich kont oraz bankomatów
z podziałem na różne statystyki. W razie wykrycia awarii jednego z bankomatów pracownik może zgłosić 
jego awarię.
