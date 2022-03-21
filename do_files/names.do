clear
cd "`root'/stata"
set more off 

*******************************************************************************
*
*     Correct names data set 05/26/20 
*	Edited, 2/14/22, S. Doshi
*
*******************************************************************************
import excel using "raw_data/names_2digit_corrected.xlsx", case(lower) first clear 

duplicates tag country,gen(tag)
gsort -tag
drop tag
replace country="MNE" if country2=="ME" //according to google
replace country="MKD" if country2=="MK" //according to google
drop if inlist(country2,"EU28","EA19","EA12","EU15","EU27_2019","EA")
drop if country=="EURO"

*change country names to match names.dta 
replace name="Uganda" if country=="UGA" //country==unknown
replace name="Kosovo" if country=="UNK" //country==unknown
replace name="Azerbaijan" if name=="Azerbaidjan"
replace name="Bosnia and Herzegovina" if name=="Bosnia-Herzegovina"
replace name="Congo_the Democratic Republic of the" if name=="Congo, Dem. Rep. Of"
replace name="Cote d'Ivoire" if name=="Côte d'Ivoire"
replace name="Falkland Islands (Malvinas)" if name=="Falkland Islands"
replace name="Iran, Islamic Republic of" if name=="Iran"
replace name="Korea, Democratic People's Republic of" if name=="North Korea"
replace name="Korea, Republic of" if name=="South Korea"
replace name="Kyrgyzstan" if name=="Kirghizistan"
replace name="Lao People's Democratic Republic" if name=="Laos"
replace name="Libyan Arab Jamahiriya" if name=="Libya"
replace name="Macao" if name=="Macau"
replace name="Macedonia, the former Yugoslav Republic of" if name=="Macedonia"
replace name="Micronesia, Federated States of" if name=="Micronesia, Federated states of"
replace name="Moldova, Republic of" if name=="Moldova"
replace name="Palau" if name=="Pacific Islands (Palau)"
replace name="Russian Federation" if name=="Russia"
replace name="Syrian Arab Republic" if name=="Syria"
replace name="Taiwan_Province of China" if name=="Chinese Taipei"
replace name="Tajikistan" if name=="Tadjikistan"
replace name="Tanzania_United Republic of" if name=="United Republic of Tanzania"
replace name="Turkmenistan" if name=="Turkménistan"
replace name="Viet Nam" if name=="Vietnam"
replace name="Virgin Islands_USA" if name=="United States Virgin Islands"
replace name="Slovakia" if name=="Slovak Republic"
replace name="Czech Rep" if name=="Czech Republic"

*change 3-digit code to match names.dta
replace country="HRV" if country=="FYUG-HRV"
replace country="EST" if country=="USSR-EST"
replace country="LVA" if country=="USSR-LVA"
replace country="LTU" if country=="USSR-LTU"
replace country="RUS" if country=="USSR-RUS"

rename (country name country2) (ID country ID_2digit)
save data/names.dta,replace

