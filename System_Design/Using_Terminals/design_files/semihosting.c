/********************************************************************************
* C Program that asks the user for their name then prints it in three different
*ways.
********************************************************************************/
#include <stdio.h>
int main(void) {
    char name[64];
    
    // Get user's name
    printf("Hello, what is your name?\n");
    scanf("%s", name);
    
    printf("Your name is:\n");
    
    // Print the user's name in 3 different ways
    printf("%s\n", name);
    puts(name);
    fprintf(stdout, "%s\n", name);
    
    return 0;
}
