#include<stdio.h>
#include<math.h>


int main()
{
   int i,j,a,b;
   int count;
   
   printf("Start?: ");
   scanf("%d",&a);
   
   printf("End?: ");
   scanf("%d",&b);
   
   for(i = a; i < b; i++)
   {
      for(j = 2; j < i; j++)
      {
         if(i % j == 0)
         break;
      }
      if(i == j)
      {
         count++;
         printf("\n%d",j);
      }
   }
   printf("\n");
   printf("Total: %i prime numbers\n",count);
   return 0;
}
