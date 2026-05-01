/*******************************************************************************
 * This program demonstrates use of floating-point numbers
 *
 * It performs the following:
 *		1. initializes two fp variables
 *		2. performs +, -, *, and / on the variables
 *		3. shows the results with printf
 ******************************************************************************/
#include <stdio.h>

int main(void) 
{
    float x, y, add, sub, mult, div;

    while (1) {
        printf("Enter a number for X, then press Enter: ");
        fflush(stdout);
        scanf("%f", &x);
        printf("%f\n", x); // echo the typed data to the Terminal window
                           //
        printf("Enter a number for Y, then press Enter: ");
        fflush(stdout);
        scanf("%f", &y);
        printf("%f\n", y); // echo the typed data to the Terminal window

        add = x + y;
        sub = x - y;
        mult = x * y;
        div = x / y;
        printf("X + Y = %f\n", add);
        printf("X - Y = %f\n", sub);
        printf("X * Y = %f\n", mult);
        printf("X / Y = %f\n", div);
    }
}
