EESchema Schematic File Version 4
EELAYER 30 0
EELAYER END
$Descr A4 11693 8268
encoding utf-8
Sheet 1 1
Title ""
Date ""
Rev ""
Comp ""
Comment1 ""
Comment2 ""
Comment3 ""
Comment4 ""
$EndDescr
Connection ~ 9450 3150
Wire Wire Line
	9450 4250 9550 4250
Wire Wire Line
	9450 3150 9450 4250
Entry Bus Bus
	9550 4250 9650 4350
Connection ~ 5450 4950
Wire Wire Line
	5150 4950 5450 4950
Wire Wire Line
	9050 2600 9150 2600
Connection ~ 9050 2600
Wire Wire Line
	9050 2650 9050 2600
Wire Wire Line
	8850 2650 9050 2650
Wire Wire Line
	8850 3050 8850 2650
Wire Wire Line
	8950 2600 9050 2600
Wire Wire Line
	6250 4000 6250 3450
Connection ~ 6250 4000
Wire Wire Line
	8850 4000 6250 4000
Wire Wire Line
	8850 3250 8850 4000
Wire Wire Line
	9450 3150 9450 2600
$Comp
L pspice:OPAMP U13
U 1 1 60697395
P 9150 3150
F 0 "U13" H 9494 3196 50  0000 L CNN
F 1 "OPAMP" H 9494 3105 50  0000 L CNN
F 2 "" H 9150 3150 50  0001 C CNN
F 3 "~" H 9150 3150 50  0001 C CNN
	1    9150 3150
	1    0    0    -1  
$EndComp
$Comp
L Device:R_US R29
U 1 1 60696097
P 9300 2600
F 0 "R29" V 9095 2600 50  0000 C CNN
F 1 "100k" V 9186 2600 50  0000 C CNN
F 2 "" V 9340 2590 50  0001 C CNN
F 3 "~" H 9300 2600 50  0001 C CNN
	1    9300 2600
	0    1    1    0   
$EndComp
$Comp
L Device:R_US R30
U 1 1 60694FD4
P 8800 2600
F 0 "R30" V 8595 2600 50  0000 C CNN
F 1 "27k" V 8686 2600 50  0000 C CNN
F 2 "" V 8840 2590 50  0001 C CNN
F 3 "~" H 8800 2600 50  0001 C CNN
	1    8800 2600
	0    1    1    0   
$EndComp
$Comp
L pspice:CAP C15
U 1 1 6068D606
P 8400 2600
F 0 "C15" V 8085 2600 50  0000 C CNN
F 1 ".22" V 8176 2600 50  0000 C CNN
F 2 "" H 8400 2600 50  0001 C CNN
F 3 "~" H 8400 2600 50  0001 C CNN
	1    8400 2600
	0    1    1    0   
$EndComp
Connection ~ 7250 2600
Wire Wire Line
	7850 2600 7250 2600
$Comp
L Device:R_US R9
U 1 1 6063973D
P 8000 2600
F 0 "R9" V 7795 2600 50  0000 C CNN
F 1 "10k" V 7886 2600 50  0000 C CNN
F 2 "" V 8040 2590 50  0001 C CNN
F 3 "~" H 8000 2600 50  0001 C CNN
	1    8000 2600
	0    1    1    0   
$EndComp
Wire Wire Line
	7250 3350 7250 2600
Wire Wire Line
	6100 4950 6250 4950
Connection ~ 6100 4950
Wire Wire Line
	6100 5050 6100 4950
Wire Wire Line
	5450 4950 6100 4950
Wire Wire Line
	5450 5050 5450 4950
Wire Wire Line
	6250 3450 6650 3450
Wire Wire Line
	6250 4950 6250 4000
Wire Wire Line
	4500 4950 4850 4950
$Comp
L power:Earth #PWR0106
U 1 1 605D7030
P 5450 5550
F 0 "#PWR0106" H 5450 5300 50  0001 C CNN
F 1 "Earth" H 5450 5400 50  0001 C CNN
F 2 "" H 5450 5550 50  0001 C CNN
F 3 "~" H 5450 5550 50  0001 C CNN
	1    5450 5550
	1    0    0    -1  
$EndComp
$Comp
L power:Earth #PWR0105
U 1 1 605D60F4
P 6100 5550
F 0 "#PWR0105" H 6100 5300 50  0001 C CNN
F 1 "Earth" H 6100 5400 50  0001 C CNN
F 2 "" H 6100 5550 50  0001 C CNN
F 3 "~" H 6100 5550 50  0001 C CNN
	1    6100 5550
	1    0    0    -1  
$EndComp
$Comp
L pspice:CAP C30
U 1 1 605D4337
P 6100 5300
F 0 "C30" H 6278 5346 50  0000 L CNN
F 1 "10" H 6278 5255 50  0000 L CNN
F 2 "" H 6100 5300 50  0001 C CNN
F 3 "~" H 6100 5300 50  0001 C CNN
	1    6100 5300
	1    0    0    -1  
$EndComp
$Comp
L pspice:CAP C31
U 1 1 605D1DFB
P 5450 5300
F 0 "C31" H 5628 5346 50  0000 L CNN
F 1 ".1" H 5628 5255 50  0000 L CNN
F 2 "" H 5450 5300 50  0001 C CNN
F 3 "~" H 5450 5300 50  0001 C CNN
	1    5450 5300
	1    0    0    -1  
$EndComp
$Comp
L Device:R_US R1
U 1 1 605D0F88
P 5000 4950
F 0 "R1" V 4795 4950 50  0000 C CNN
F 1 "R_US" V 4886 4950 50  0000 C CNN
F 2 "" V 5040 4940 50  0001 C CNN
F 3 "~" H 5000 4950 50  0001 C CNN
	1    5000 4950
	0    1    1    0   
$EndComp
$Comp
L power:Earth #PWR0104
U 1 1 605BAA53
P 4500 5350
F 0 "#PWR0104" H 4500 5100 50  0001 C CNN
F 1 "Earth" H 4500 5200 50  0001 C CNN
F 2 "" H 4500 5350 50  0001 C CNN
F 3 "~" H 4500 5350 50  0001 C CNN
	1    4500 5350
	1    0    0    -1  
$EndComp
$Comp
L Simulation_SPICE:VDC 5V1
U 1 1 605BAA4D
P 4500 5150
F 0 "5V1" H 4630 5241 50  0000 L CNN
F 1 "5V" H 4630 5150 50  0000 L CNN
F 2 "" H 4500 5150 50  0001 C CNN
F 3 "~" H 4500 5150 50  0001 C CNN
F 4 "Y" H 4500 5150 50  0001 L CNN "Spice_Netlist_Enabled"
F 5 "V" H 4500 5150 50  0001 L CNN "Spice_Primitive"
F 6 "dc(1)" H 4630 5059 50  0000 L CNN "Spice_Model"
	1    4500 5150
	1    0    0    -1  
$EndComp
Wire Wire Line
	6850 2450 6850 3050
Wire Wire Line
	7700 2450 6850 2450
Wire Wire Line
	7700 4200 7700 2450
Wire Wire Line
	6850 4200 7700 4200
Wire Wire Line
	6850 4650 6850 4200
$Comp
L power:Earth #PWR0103
U 1 1 605B0F65
P 6850 5050
F 0 "#PWR0103" H 6850 4800 50  0001 C CNN
F 1 "Earth" H 6850 4900 50  0001 C CNN
F 2 "" H 6850 5050 50  0001 C CNN
F 3 "~" H 6850 5050 50  0001 C CNN
	1    6850 5050
	1    0    0    -1  
$EndComp
$Comp
L Simulation_SPICE:VDC 22V1
U 1 1 605AEF2A
P 6850 4850
F 0 "22V1" H 6980 4941 50  0000 L CNN
F 1 "22V" H 6980 4850 50  0000 L CNN
F 2 "" H 6850 4850 50  0001 C CNN
F 3 "~" H 6850 4850 50  0001 C CNN
F 4 "Y" H 6850 4850 50  0001 L CNN "Spice_Netlist_Enabled"
F 5 "V" H 6850 4850 50  0001 L CNN "Spice_Primitive"
F 6 "dc(1)" H 6980 4759 50  0000 L CNN "Spice_Model"
	1    6850 4850
	1    0    0    -1  
$EndComp
$Comp
L power:Earth #PWR0102
U 1 1 6059BB74
P 6850 3650
F 0 "#PWR0102" H 6850 3400 50  0001 C CNN
F 1 "Earth" H 6850 3500 50  0001 C CNN
F 2 "" H 6850 3650 50  0001 C CNN
F 3 "~" H 6850 3650 50  0001 C CNN
	1    6850 3650
	1    0    0    -1  
$EndComp
Connection ~ 6250 2600
Connection ~ 6250 3250
Wire Wire Line
	6650 3250 6250 3250
$Comp
L pspice:OPAMP K4
U 1 1 605720B1
P 6950 3350
F 0 "K4" H 7294 3396 50  0000 L CNN
F 1 "OPAMP" H 7294 3305 50  0000 L CNN
F 2 "" H 6950 3350 50  0001 C CNN
F 3 "~" H 6950 3350 50  0001 C CNN
	1    6950 3350
	1    0    0    -1  
$EndComp
Wire Wire Line
	6250 3250 6250 3050
Wire Wire Line
	6050 3250 6250 3250
Wire Wire Line
	6250 2600 6050 2600
Wire Wire Line
	6250 2750 6250 2600
$Comp
L Device:R_US R25
U 1 1 60569DE5
P 6250 2900
F 0 "R25" H 6318 2946 50  0000 L CNN
F 1 "330k" H 6318 2855 50  0000 L CNN
F 2 "" V 6290 2890 50  0001 C CNN
F 3 "~" H 6250 2900 50  0001 C CNN
	1    6250 2900
	1    0    0    -1  
$EndComp
Connection ~ 5400 3250
Wire Wire Line
	5400 3850 5400 3250
Wire Wire Line
	5400 2600 5550 2600
Connection ~ 5400 2600
Wire Wire Line
	5400 3250 5550 3250
Wire Wire Line
	5400 2600 5400 3250
$Comp
L pspice:CAP C22
U 1 1 605528F1
P 5800 3250
F 0 "C22" V 5485 3250 50  0000 C CNN
F 1 ".1" V 5576 3250 50  0000 C CNN
F 2 "" H 5800 3250 50  0001 C CNN
F 3 "~" H 5800 3250 50  0001 C CNN
	1    5800 3250
	0    1    1    0   
$EndComp
$Comp
L pspice:CAP C21
U 1 1 60551D39
P 5800 2600
F 0 "C21" V 5485 2600 50  0000 C CNN
F 1 ".1" V 5576 2600 50  0000 C CNN
F 2 "" H 5800 2600 50  0001 C CNN
F 3 "~" H 5800 2600 50  0001 C CNN
	1    5800 2600
	0    1    1    0   
$EndComp
$Comp
L power:Earth #PWR0101
U 1 1 6054FA8A
P 5400 4150
F 0 "#PWR0101" H 5400 3900 50  0001 C CNN
F 1 "Earth" H 5400 4000 50  0001 C CNN
F 2 "" H 5400 4150 50  0001 C CNN
F 3 "~" H 5400 4150 50  0001 C CNN
	1    5400 4150
	1    0    0    -1  
$EndComp
$Comp
L Device:R_US R24
U 1 1 605421EF
P 5400 4000
F 0 "R24" H 5468 4046 50  0000 L CNN
F 1 "680" H 5468 3955 50  0000 L CNN
F 2 "" V 5440 3990 50  0001 C CNN
F 3 "~" H 5400 4000 50  0001 C CNN
	1    5400 4000
	1    0    0    -1  
$EndComp
$Comp
L Device:R_US R8
U 1 1 6053B66E
P 5150 2600
F 0 "R8" V 4945 2600 50  0000 C CNN
F 1 "5.6K" V 5036 2600 50  0000 C CNN
F 2 "" V 5190 2590 50  0001 C CNN
F 3 "~" H 5150 2600 50  0001 C CNN
	1    5150 2600
	0    1    1    0   
$EndComp
Wire Wire Line
	4800 2050 4800 1750
Wire Wire Line
	3050 2050 4800 2050
Wire Wire Line
	4550 2600 5000 2600
Wire Wire Line
	4350 4150 4550 4150
Wire Wire Line
	4550 4150 4550 3700
Connection ~ 4550 3700
Wire Wire Line
	4350 3700 4550 3700
Wire Wire Line
	4550 3700 4550 3150
Wire Wire Line
	4550 3150 4550 2600
Connection ~ 4550 3150
Wire Wire Line
	4350 3150 4550 3150
Connection ~ 4550 2600
Wire Wire Line
	4400 2600 4550 2600
Wire Wire Line
	3900 4150 4050 4150
Wire Wire Line
	3900 3700 4050 3700
Wire Wire Line
	3900 3150 4050 3150
Wire Wire Line
	3900 2600 4100 2600
$Comp
L Device:R_US R14
U 1 1 6052CEB8
P 4200 4150
F 0 "R14" V 3995 4150 50  0000 C CNN
F 1 "9.2K" V 4086 4150 50  0000 C CNN
F 2 "" V 4240 4140 50  0001 C CNN
F 3 "~" H 4200 4150 50  0001 C CNN
	1    4200 4150
	0    1    1    0   
$EndComp
$Comp
L Device:R_US R15
U 1 1 6052C19E
P 4200 3700
F 0 "R15" V 3995 3700 50  0000 C CNN
F 1 "3.9K" V 4086 3700 50  0000 C CNN
F 2 "" V 4240 3690 50  0001 C CNN
F 3 "~" H 4200 3700 50  0001 C CNN
	1    4200 3700
	0    1    1    0   
$EndComp
$Comp
L Device:R_US R6
U 1 1 6052B41F
P 4200 3150
F 0 "R6" V 3995 3150 50  0000 C CNN
F 1 "2.2K" V 4086 3150 50  0000 C CNN
F 2 "" V 4240 3140 50  0001 C CNN
F 3 "~" H 4200 3150 50  0001 C CNN
	1    4200 3150
	0    1    1    0   
$EndComp
$Comp
L Device:R_US R17
U 1 1 60503D80
P 4250 2600
F 0 "R17" V 4045 2600 50  0000 C CNN
F 1 "1K" V 4136 2600 50  0000 C CNN
F 2 "" V 4290 2590 50  0001 C CNN
F 3 "~" H 4250 2600 50  0001 C CNN
	1    4250 2600
	0    1    1    0   
$EndComp
Wire Wire Line
	2050 4250 3300 4250
Wire Wire Line
	2050 3800 3300 3800
Wire Wire Line
	2050 3250 3300 3250
$Comp
L 74xx:74LS08 U5
U 1 1 6047EC04
P 3600 2600
F 0 "U5" H 3600 2925 50  0000 C CNN
F 1 "74LS08" H 3600 2834 50  0000 C CNN
F 2 "" H 3600 2600 50  0001 C CNN
F 3 "http://www.ti.com/lit/gpn/sn74LS08" H 3600 2600 50  0001 C CNN
	1    3600 2600
	1    0    0    -1  
$EndComp
Connection ~ 3900 2600
$Comp
L 74xx:74LS08 U6
U 1 1 604827E1
P 3600 2600
F 0 "U6" H 3600 2925 50  0000 C CNN
F 1 "74LS08" H 3600 2834 50  0000 C CNN
F 2 "" H 3600 2600 50  0001 C CNN
F 3 "http://www.ti.com/lit/gpn/sn74LS08" H 3600 2600 50  0001 C CNN
	1    3600 2600
	1    0    0    -1  
$EndComp
Wire Wire Line
	3300 2800 3300 2700
Connection ~ 3300 2700
Wire Wire Line
	2050 2700 3300 2700
Entry Wire Line
	1950 4150 2050 4250
Entry Wire Line
	1950 3700 2050 3800
Entry Wire Line
	1950 3150 2050 3250
Entry Wire Line
	1950 2600 2050 2700
Connection ~ 3300 2500
Wire Wire Line
	3300 2500 3000 2500
Wire Wire Line
	3000 2500 3000 3050
Connection ~ 3000 3050
Wire Wire Line
	3300 3050 3000 3050
Wire Wire Line
	3000 3050 3000 3600
Wire Wire Line
	3000 3600 3000 4050
Connection ~ 3000 3600
Wire Wire Line
	3300 3600 3000 3600
Wire Wire Line
	3000 4050 3300 4050
Connection ~ 3000 2500
Wire Wire Line
	3000 2050 3000 2500
$Comp
L 74xx:74LS08 U12
U 1 1 6048FC55
P 3600 4150
F 0 "U12" H 3600 4475 50  0000 C CNN
F 1 "74LS08" H 3600 4384 50  0000 C CNN
F 2 "" H 3600 4150 50  0001 C CNN
F 3 "http://www.ti.com/lit/gpn/sn74LS08" H 3600 4150 50  0001 C CNN
	1    3600 4150
	1    0    0    -1  
$EndComp
Connection ~ 3900 4150
Connection ~ 3300 4250
Connection ~ 3300 4050
$Comp
L 74xx:74LS08 U11
U 1 1 6048FC4F
P 3600 4150
F 0 "U11" H 3600 4475 50  0000 C CNN
F 1 "74LS08" H 3600 4384 50  0000 C CNN
F 2 "" H 3600 4150 50  0001 C CNN
F 3 "http://www.ti.com/lit/gpn/sn74LS08" H 3600 4150 50  0001 C CNN
	1    3600 4150
	1    0    0    -1  
$EndComp
$Comp
L 74xx:74LS08 U10
U 1 1 6048C3FA
P 3600 3700
F 0 "U10" H 3600 4025 50  0000 C CNN
F 1 "74LS08" H 3600 3934 50  0000 C CNN
F 2 "" H 3600 3700 50  0001 C CNN
F 3 "http://www.ti.com/lit/gpn/sn74LS08" H 3600 3700 50  0001 C CNN
	1    3600 3700
	1    0    0    -1  
$EndComp
Connection ~ 3900 3700
Connection ~ 3300 3800
Connection ~ 3300 3600
$Comp
L 74xx:74LS08 U9
U 1 1 6048C3F4
P 3600 3700
F 0 "U9" H 3600 4025 50  0000 C CNN
F 1 "74LS08" H 3600 3934 50  0000 C CNN
F 2 "" H 3600 3700 50  0001 C CNN
F 3 "http://www.ti.com/lit/gpn/sn74LS08" H 3600 3700 50  0001 C CNN
	1    3600 3700
	1    0    0    -1  
$EndComp
$Comp
L 74xx:74LS08 U8
U 1 1 60489EC1
P 3600 3150
F 0 "U8" H 3600 3475 50  0000 C CNN
F 1 "74LS08" H 3600 3384 50  0000 C CNN
F 2 "" H 3600 3150 50  0001 C CNN
F 3 "http://www.ti.com/lit/gpn/sn74LS08" H 3600 3150 50  0001 C CNN
	1    3600 3150
	1    0    0    -1  
$EndComp
Connection ~ 3900 3150
Connection ~ 3300 3250
Connection ~ 3300 3050
$Comp
L 74xx:74LS08 U7
U 1 1 60489EBB
P 3600 3150
F 0 "U7" H 3600 3475 50  0000 C CNN
F 1 "74LS08" H 3600 3384 50  0000 C CNN
F 2 "" H 3600 3150 50  0001 C CNN
F 3 "http://www.ti.com/lit/gpn/sn74LS08" H 3600 3150 50  0001 C CNN
	1    3600 3150
	1    0    0    -1  
$EndComp
Wire Wire Line
	7250 2600 6250 2600
Wire Wire Line
	5300 2600 5400 2600
$EndSCHEMATC