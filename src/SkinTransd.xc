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
#include <math.h>
#include <stdlib.h>
#include <string.h>

/*
 * defines
 */

#define HALFTIME_40KHZ 1250 //1250
#define FLASH_PERIOD 20000000
#define PULSES 10   //40000*2
#define SAMPLES 200
#define TRANSD 4
#define PULSE_REPETITION_RATE 300000000 // 2 seconds
#define TIMER_FREQUENCY 10 //MHz
#define FREQUENCY 40000 // Hz

/*
 * ports
 */
//out buffered port:4 outP4  = XS1_PORT_4A;
out buffered port:4 outP   = XS1_PORT_4A; // BLUE,GREEN,BLUE,GREEN
in buffered port:1 inP     = XS1_PORT_1E; // GPIO B GREY
in port BUT1    = XS1_PORT_1K;
in port button2 = XS1_PORT_1L;
out port LED = XS1_PORT_4F;

/*
 * timers and clock
 */
out port outClock = XS1_PORT_1D;
clock    clk      = XS1_CLKBLK_1;

/*
 *DEBBUGGING FUNCTION
 */
void transmitInf(out port outP, int onTime, int offTime); // function for debbugging
int menu(); // only a simple menu for debbugging
void flush_in();
void waitForButtonClick(in port button); // function for debbugging
void waitSecond(unsigned delay);// function for debbuging
int lastposition(int buffer[], int length); // function for debbugging
void flashLED(out port led,int freq); // function for debbugging
void printBuffer(int buffer[], int length); // function for debbugging
void copyBuffer(int a[],int b[], int lenght);

/*
 * PRINCIPAL FUNCTION
 */
void initBuffer(int buffer[], int length); // buffer = 0
void transmitPulsesTicks(out buffered port:4 outP,int pulses,int ticks,int transd);
void infinite40hz(out buffered port:4 outP); // endless loop 40kHz
void transmitInfTimer(out buffered port:4 outP, int onTime, int offTime); // endless loop by timer
void transmitInfTicks(out buffered port:4 outP, int ticks); // endless loop by ticks
void transmitPulsesTimer(out buffered port:4 outP, int onTime, int offTime,
        int pulses,int transd); // transmitt num of pulses we indicate
void transmitBuffer(out buffered port:4 outP,int buffer[], int num_samples);
void transmitBuffer_reversal(out buffered port:4 outP,int buffer[], int num_samples);
void receiveBuffer(in buffered port:1 inP,int buffer[],int length, int transd);
void transmitt_receive_timer(clock c, in buffered port:1 inP,
            out buffered port:4 outP,int buffer[], int time_delay, int transd);
void transmitt_receive_ticks(clock c, in buffered port:1 inP,out buffered port:4 outP,
                        int buffer[],int ticks,int transd);
void calculateFrequency(int timer_F, int freq, int &ticks); // function calculate the ticks for differences FREQUENCY
void calculateTimer(int frequency, int &timedelay); // time delay for frequency (100MHz)
int firstPosition(int buffer[], int length); // auxiliar function
void transducer4receiver1(out buffered port:4 outP, in port inP, int buffer[],
        int pulses,int ticks); // general function
void invertBuffer(int buffer[], int auxBuffer[],int length, int transducer); //we detecte negative logic 0 -> 1
void invertValuesBuffer(int buffer[],int auxBuffer[],int pos, int length, int trans); //auxiliar function
void reverse(int buffer[], int lenght);
void fristPositionTransducers(int buffer[],int pos[], int lenght);

void algorithm_time_reversal(out buffered port:4 outP, int buffer[]);
void create_buffer_time_delay(int buffer[],int lenght_buffer,int delays[],
        int transd, int maxDelay, int ticks);
int maxDelays(int delays[],int transd);

void algorithm_time_delay(out buffered port:4 outP,int buffer[], int ticks);




/*
-------------------------------------------//
*
*          MAIN
*
*/
int main(void)
{
    /*
     * init variables
     */
    int buffer[SAMPLES];
    initBuffer(buffer,SAMPLES);
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
    calculateTimer(FREQUENCY,half_wave);

    printf("%d\n",ticks);

    while(1)
    {

        op = menu();
        switch (op)
        {
            case 1:

                //transmitInfTicks(outP,ticks);
                //transmitInfTimer(outP, HALFTIME_40KHZ, HALFTIME_40KHZ);
                transmitInfTimer(outP, half_wave, half_wave);
                break;
            case 2:
                while(1)
                {
                    int t = 0;
                    while(t<4)
                    {
                        transmitt_receive_timer(clk,inP,outP,buffer,half_wave,t);
                        waitSecond(PULSE_REPETITION_RATE);
                        t++;
                    }
                    algorithm_time_reversal(outP,buffer);

                    //transmitBuffer(outP,buffer,SAMPLES);
                    initBuffer(buffer, SAMPLES);
                    waitSecond(PULSE_REPETITION_RATE);
                }

                break;
            case 3:
                //transmitt_receive_ticks(clk, inP,outP,buffer, ticks,transd);

                while(1)
                {
                    int t = 0;
                    while(t<4)
                    {
                        transmitt_receive_timer(clk,inP,outP,buffer,half_wave,t);
                        waitSecond(PULSE_REPETITION_RATE);
                        t++;
                    }
                    //algorithm_time_reversal(outP,buffer);
                    algorithm_time_delay(outP,buffer, ticks);
                    //transmitBuffer(outP,buffer,SAMPLES);
                    initBuffer(buffer, SAMPLES);
                    waitSecond(PULSE_REPETITION_RATE);
                }


                break;
            case 4:
                printf("test: 4 transducer sending\n");

                for(int i=0; i<4;i++)transmitt_receive_timer(clk,inP,outP,buffer,half_wave,1);
                /*
                while(1)
                {
                    waitForButtonClick(BUT1);
                    output_input_ticks(BUT1,clk, inP,outP,buffer, ticks,transd);
                    transd++;
                    if(transd>4) transd = 1;
                }
                */
                break;
            default:
                break;
        }
        flush_in();
    }

    return 0;
}

void transmitt_receive_timer(clock c, in buffered port:1 inP,
            out buffered port:4 outP,int buffer[], int time_delay,int transd)
{
    par
    {
        transmitPulsesTimer(outP,time_delay, time_delay,PULSES,transd);
        receiveBuffer(inP,buffer,SAMPLES,transd);
    }
    //firstPosition(buffer,SAMPLES);
    //lastposition(buffer,SAMPLES);
    transmitBuffer(outP,buffer,SAMPLES);
}
void transmitt_receive_ticks(clock c, in buffered port:1 inP,
        out buffered port:4 outP,int buffer[],int ticks,int transd)
{
        par
        {
            transmitPulsesTicks(outP,PULSES,ticks,transd);
            receiveBuffer(inP,buffer,SAMPLES,transd);
        }

        //  printBuffer(buffer,SAMPLES); fuction for debbuging
         transmitBuffer(outP,buffer,SAMPLES);


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
    /*
     * previosly we calculated the ticks, and we transmitt tick of frequency half UP and half DOWN
     */

    int halfTicks = ticks/2;

    //printf("ticks/2 %d\n", halfTicks);

    while(1)
    {
        for (int i = 0; i<halfTicks; i++)
        {
            outP <: 1111; // up
        }
        for (int i = 0; i<halfTicks; i++)
        {
            outP <: 0; // down
        }
    }
}
int menu()
{
    char c;
    printf("SKIN TRANSDUCER \n");
    printf("=============== \n");
    printf("a) infinite WAVES \n");
    printf("b) Transmit - Receive: algorithm Time reversal\n");
    printf("c) Transmit - Receive: algorithm Time delay \n");
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
    /*
     * transmit buffer from last position til 0
     */
    for(int j=0; j<num_samples ; j++)
    {
        outP <: buffer[j];
    }

    //firstPosition(buffer,SAMPLES);
    //lastposition(buffer,SAMPLES);
    //printBuffer(buffer,SAMPLES);


}
void receiveBuffer(in buffered port:1 inP,int buffer[],int length, int transd)
{
    int value_inport;
    for(int i=0 ; i<length ; i++)
    {
       inP :> value_inport;
       buffer[i] = value_inport*pow(2,transd);
    }
    //invertBuffer(buffer,auxBuffer,length, transd); // buffer <- auxBuffer (invert logic)
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
void transmitPulsesTimer(out buffered port:4 outP, int onTime, int offTime,int pulses,int transd)
{
    timer t;
    unsigned currentTime;
    t:>currentTime;

    for(int i=0; i<pulses; i++)
    {
    // turn ON
        outP <:1 << transd;             // all outputs
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
        printf("%i \n",buffer[i]);
    }
}
int firstPosition(int buffer[], int length)
{
    int pos = 0;

    for (int i =0; i<length; i++)
    {
        if(buffer[i]==1)
        {
            pos = i;
            return pos;
        }
    }
    return pos;
}
void invertBuffer(int buffer[],int auxBuffer[], int length, int transd)
{
    //when I found 1, change invert logic
    int posFirstOne = firstPosition(auxBuffer,length);
    invertValuesBuffer(buffer,auxBuffer,posFirstOne,length,transd);
}
void invertValuesBuffer(int buffer[],int auxBuffer[],int pos, int length, int transducer)
{
    // buffer <- inver(auxBuffer) << to position this transducer
    printf("transducer %i\n", transducer);
    for(int i = pos; i<length; i++)
    {
        //negative logic
        if(auxBuffer[i]==0)
        {
             buffer[i] += pow(2,transducer);
        }
    }
}
int lastposition(int buffer[],int length)
{
    int pos = 0;
    for (int i=0; i<length; i++)
    {
        if(buffer[i]==1) pos = i;
    }
    //printf("the last possition with 1 is: %d\n", pos);
    return pos;
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
void initBuffer(int buffer[], int length)
{
    /*
     * buffer = 0
     */
    for(int i=0; i<length; i++)
    {
        buffer[i]=0;
    }
}
void waitSecond(unsigned delay)
{
    timer tmr;
    int t;
    tmr :> t;
    tmr when timerafter(t+PULSE_REPETITION_RATE) :> void;

}
void algorithm_time_reversal(out buffered port:4 outP, int buffer[])
{
    int pos[TRANSD];
    fristPositionTransducers(buffer,pos,SAMPLES);
    int result;
    for(int i=0; i<SAMPLES; i++)
    {
        if(i>=pos[0])
        {
            result = pow(2,0);
            if((buffer[i] & result)>0) buffer[i]-= result;
            else buffer[i]+= result;
        }
        if(i>=pos[1])
        {
            result = pow(2,1);
            if((buffer[i] & result)>0) buffer[i]-= result;
            else buffer[i]+= result;
        }
        if(i>=pos[2])
        {
            result = pow(2,2);
            if((buffer[i] & result)>0) buffer[i]-= result;
            else buffer[i]+= result;
        }
        if(i>=pos[3])
        {
            result = pow(2,3);
            if((buffer[i] & result)>0) buffer[i]-= result;
            else buffer[i]+= result;
        }
    }
    transmitBuffer_reversal(outP,buffer, SAMPLES);
    //reverse(buffer,SAMPLES);
}

void reverse(int buffer[], int lenght)
{
    int auxBuffer[SAMPLES];
    copyBuffer(auxBuffer,buffer,SAMPLES);
    int auxPos = lenght;
    for(int j=0; j>lenght; j++)
    {
        buffer[j] = auxBuffer[auxPos];
        auxPos--;
    }
}
void fristPositionTransducers(int buffer[],int pos[], int lenght)
{
    for(int i=0; i<lenght; i++)
    {
        for(int j=0; j<4; j++)
        {
            int compAnd = pow(2,j);

            if((buffer[i] & compAnd) > 0)
            {
                if(j==0 && (pos[0]==0)) pos[0] = i;
                if(j==1 && (pos[1]==0)) pos[1] = i;
                if(j==2 && (pos[2]==0)) pos[2] = i;
                if(j==3 && (pos[3]==0)) pos[3] = i;
            }
        }
    }
}


void copyBuffer(int a[],int b[], int lenght)
{
    for(int i=0; i<lenght; i++) a[i]=b[i];
}
void transmitBuffer_reversal(out buffered port:4 outP,int buffer[], int num_samples)
{
    for(int j=num_samples-1; j>=0 ; j--)
    {
        outP <: buffer[j];
    }
}
void algorithm_time_delay(out buffered port:4 outP,int buffer[], int ticks)
{
    int delays[TRANSD];

    fristPositionTransducers(buffer,delays,SAMPLES);
    int maxDelay = maxDelays(delays,TRANSD);
    int tam_buffer = ticks+(maxDelay*2);
    //int auxBuffer[tam_buffer];
    int auxBuffer[5000];
    create_buffer_time_delay(auxBuffer,tam_buffer,delays,TRANSD,maxDelay,ticks);

    //for(int i=0; i<num_pulses; i++);
    //{
        transmitBuffer(outP,auxBuffer,tam_buffer);
    //}

}
void create_buffer_time_delay(int buffer[],int lenght_buffer,int delays[],int transd, int maxDelay,
        int ticks)
{
    /*
     * create the buffer with delays, later I will send
     * buffer is initializated so I will write the 1 for the frequency we said before
     */
    int start = 0;
    int ticksUp = ticks/2;

    initBuffer(buffer,lenght_buffer);

    for(int t=0; t<transd; t++)
    {
        start = maxDelay - delays[t];
        for(int i = start; i<ticksUp+start; i++)
        {
            buffer[i]+= pow(2,t);
        }
    }

}
int maxDelays(int delays[],int transd)
{
    //calculate max delay the every transducer
    int max = 0;
    for(int i=0; i<transd; i++)
    {
        if(delays[i]>max) max = delays[i];
    }
    return max;
}

















