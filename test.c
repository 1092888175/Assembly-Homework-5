#include<stdio.h>
long long v_a = 1;
long long v_b = 2;
long long v_c = 0;
int main(){
    asm volatile(          
    "addq %%rbx,%%rax"
    :"=a"(v_c)
    :"a"(v_a),"b"(v_b)
    );
    printf("%d\n",v_c);
}