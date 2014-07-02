/*
 * SkinTransducer.xc
 *
 *  Created on: 20 Jun 2014
 *      Author: RM
 */
#include <xclib.h>
#include <print.h>
#include <xs1.h>
#include <stdio.h>
#include <timer.h>

#include <stdlib.h>
#include <string.h>

#define HALFTIME_40KHZ 1250 //1250
#define FLASH_PERIOD 20000000
#define PULSES 2000   //40000*2
#define SAMPLES 100
#define TRANSD 4

#define TIMER_FREQUENCY 10 //MHz
#define FREQUENCY 40000 // Hz

//out buffered port:4 outP4  = XS1_PORT_4A;

out buffered port:4 outP   = XS1_PORT_4A; // BLUE,GREEN,BLUE,GREEN
in buffered port:1 inP     = XS1_PORT_1A; // GREY
in port BUT1    = XS1_PORT_1K;
in port button2 = XS1_PORT_1L;
out port LED = XS1_PORT_4F;




out port outClock = XS1_PORT_1D;
clock    clk      = XS1_CLKBLK_1;

void transmitPulsesTicks(out buffered port:4 outP,int pulses,int ticks,int transd);
//void transmitPulsesTicks(out buffered port:4 outP,int pulses,int ticks,int transd);
void infinite40hz(out buffered port:4 outP);
//void transmitInfTimer(out buffered port:4 outP, int onTime, int offTime);
void transmitInfTimer(out buffered port:4 outP, int onTime, int offTime);
void transmitInfTicks(out buffered port:4 outP, int ticks);
void transmitPulsesTimer(out buffered port:4 outP, int onTime, int offTime,int pulses);
int menu();
void flush_in();
void transmitBuffer(out buffered port:4 outP,int buffer[], int num_samples);
void receiveBuffer(in buffered port:1 inP,int buffer[], int transd);
void output_input_timer(in port p_button,clock c, in buffered port:1 inP,
            out buffered port:4 outP,int buffer[], int time_delay);
void output_input_ticks(in port p_button,clock c, in buffered port:1 inP,out buffered port:4 outP,
                        int buffer[],int ticks,int transd);
void waitForButtonClick(in port button);

void transmitInf(out port pA, int onTime, int offTime);
void calculateFrequency(int timer_F, int freq, int &ticks);
void calculateTimer(int frequency, int &timedelay);
void printBuffer(int buffer[], int length);
void firstPosition(int buffer[], int length);
void invertBuffer(int buffer[], int length);
void lastposition(int buffer[], int length);
void invertBuffer(int buffer[], int length);
void flashLED(out port led,int freq);

/*
-------------------------------------------//
*
*          MAIN
*
*/
int main(void)
{


    int buffer[SAMPLES];
    int transd=0;


    int op;
    int ticks=0;
    int half_wave;

    configure_clock_rate(clk,TIMER_FREQUENCY,1);
    //configure_port_clock_output(clk, clk);
    configure_out_port(outP, clk, 0);
    //configure_out_port(outP4, clk, 0);

    configure_in_port(inP,clk);
    configure_port_clock_output(outClock,clk);


    start_clock(clk);

    outP <: 0; // start an output
    sync(outP);
    calculateFrequency(TIMER_FREQUENCY,FREQUENCY,ticks);

    while(1)
    {

        op = menu();
        switch (op)
        {
            case 1:

               // transmitInfTicks(outP,ticks);
                //transmitInfTimer(outP, HALFTIME_40KHZ, HALFTIME_40KHZ);
                transmitInfTimer(outP, half_wave, half_wave);
                break;
            case 2:
                calculateTimer(FREQUENCY,half_wave);
                output_input_timer(BUT1,clk,inP,outP,buffer,half_wave);

                break;
            case 3:
                calculateFrequency(TIMER_FREQUENCY,FREQUENCY,ticks);
                output_input_ticks(BUT1,clk, inP,outP,buffer, ticks,transd);

                break;
            case 4:
                printf("test: 4 transducer sending\n");
                while(1)
                {
                    waitForButtonClick(BUT1);
                    output_input_ticks(BUT1,clk, inP,outP,buffer, ticks,transd);
                    transd++;
                    if(transd>4) transd = 1;
                }
                break;
            default:
                break;
        }
        flush_in();
    }

    return 0;
}

void output_input_timer(in port p_button,clock c, in buffered port:1 inP,
            out buffered port:4 outP,int buffer[], int time_delay)
{
    par
    {
        transmitPulsesTimer(outP,time_delay, time_delay,PULSES);
        receiveBuffer(inP,buffer,1);
    }
    firstPosition(buffer,SAMPLES);
    lastposition(buffer,SAMPLES);
    //transmitBuffer(outP,buffer,SAMPLES);


}
void output_input_ticks(in port p_button,clock c, in buffered port:1 inP,out buffered port:4 outP,
                        int buffer[],int ticks,int transd)
{

    par
    {
        transmitPulsesTicks(outP,PULSES,ticks,transd);
        receiveBuffer(inP,buffer,transd);
    }
    //invertBuffer(buffer,SAMPLES);
    //firstPosition(buffer,SAMPLES);
    //lastposition(buffer,SAMPLES);
    printBuffer(buffer,SAMPLES);
    // transmitBuffer(outP,buffer,SAMPLES);


}
void transmitPulsesTicks(out buffered port:4 outP,int pulses,int ticks,int transd)
{
    for(int j=0; j<pulses; j++)
    {
        for (int i = 0; i<ticks/2; i++) {
            outP <: 1 << transd;
        }
        for (int i = 0; i<ticks/2; i++) {
            outP <: 0;
        }
    }
}


void transmitInfTicks(out buffered port:4 outP, int ticks)
{
    while(1)
    {
        for (int i = 0; i<ticks/2; i++)
        {
            outP <: 1; // down
        }
        for (int i = 0; i<ticks/2; i++)
        {
            outP <: 0;
        }
    }
}
int menu()
{
    char c;
    printf("SKIN TRANSDUCER \n");
    printf("=============== \n");
    printf("a) infinite WAVES \n");
    printf("b) Receive-Transmitter Buffer with this pulses (TIMERS) %d \n", PULSES);
    printf("c) Receive-Transmitter Buffer with this pulses (ticks) %d \n", PULSES);
    printf("d) Test  \n");
    printf("e) Other to end \n");
    printf("================= \n");

    scanf("%c", &c);
    //c = getchar();

    if(c=='a' || c=='1') return 1;
    if(c =='b' || c=='2') return 2;
    if(c=='c' || c=='3') return 3;
    if(c=='d' || c=='4') return 4;

    return 0;
}

void transmitBuffer(out buffered port:4 outP,int buffer[], int num_samples)
{
    for(int j=num_samples-1; j>=0 ; j--)
    {
        outP <: buffer[j];
    }

}
void receiveBuffer(in buffered port:1 inP,int buffer[], int transd)
{
    int aux;
     for(int i=0 ; i<SAMPLES ; i++)
     {
         inP :> aux;
         //buffer[i] = buffer[i] << transd;
         buffer[i] = aux << transd;
     }
}
void waitForButtonClick(in port button)
{
    button when pinseq(0) :> void;  // wait to be pressed
    button when pinseq(1) :> void;  // wait for release
}

void flush_in()
{
    int ch;

    while( (ch = fgetc(stdin)) != EOF && ch != '\n' ){}
}
void transmitPulsesTimer(out buffered port:4 outP, int onTime, int offTime,int pulses)
{
    timer t;
    unsigned currentTime;
    t:>currentTime;

    for(int i=0; i<pulses; i++)
    {
    // turn ON
        outP <:15;             // all outputs
        currentTime += onTime;
        t when timerafter (currentTime) :> void;

        // turn OFF
        outP <:0;
        currentTime += offTime;
        t when timerafter (currentTime) :> void;
    }
}
void transmitInfTimer(out buffered port:4 outP, int onTime, int offTime)
{
    timer t;
    unsigned currentTime;
    t:>currentTime;
    while(1)
    {
        // turn ON
        outP <:15;             // all outputs
        currentTime += onTime;
        t when timerafter (currentTime) :> void;

        // turn OFF
        outP <:0;
        currentTime += offTime;
        t when timerafter (currentTime) :> void;
    }
}
void calculateTimer(int frequency, int &timedelay)
{
    calculateFrequency(100,frequency,timedelay);

    timedelay = timedelay/2;
}
void calculateFrequency(int timer_F, int freq, int &ticks)
{
    ticks = (timer_F *1000000)/freq;
}
void printBuffer(int buffer[], int length)
{
    printf("print values on the buffer: \n");
    for(int i=0 ; i<length ; i++)
    {
        printf("index %d ",i);
        printf("%x \n",buffer[i]);
    }
}
void firstPosition(int buffer[], int length)
{
    int pos = 0;

    for (int i =0; i<length; i++)
    {
            if(buffer[i]==1)
            {
                pos = i;
                break ;
            }
    }
    printf("the first possition with 1 is: %d \n", pos);
}
void invertBuffer(int buffer[], int length)
{
    for(int i=0; i<length; i++) buffer[i]=~buffer[i];
}
void lastposition(int buffer[],int length)
{
    int pos = 0;
    for (int i=0; i<length; i++)
    {
        if(buffer[i]==1) pos = i;
    }
    printf("the last possition with 1 is: %d\n", pos);
}
void flashLED(out port led,int freq)
{
    timer tmr;
    int t;
    tmr :> t;

    led <: 0x1;
    t += freq;
    tmr when timerafter(t) :> void;
    led <: 0x0;
    t += freq;
    tmr when timerafter(t) :> void;

}





