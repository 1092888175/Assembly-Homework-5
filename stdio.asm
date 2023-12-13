# 在Linux X86-64汇编中，系统调用由syscall指令调用
# 在%rax寄存器中存储系统调用编号
# 在%rdi，%rsi，%rdx寄存器分别存放移送给系统调用的第一、二、三个参数
# 系统调用的返回值存储在%rax寄存器中
# 在本次作业中使用到的系统调用表如下
#   %rax    System Call     %rdi            %rsi            %rdx
#   1       sys_write       unsigned int fd const char* buf size_t count
#   60      sys_exit        int error_code

# X86-64 Linux 中各寄存器的保存要求
# Caller Save：%rax %rcx %rdx %rsp %rsi %rdi %r8 %r9 %r10 %r11
# Callee Save：%rbx %rbp %r12 %r13 %r14 %r15

# 声明一个用于调用sys_write 和 sys_read 的宏
# 其按顺序将参数赋给%rax %rdi %rsi %rdx并调用系统调用
.macro sys_io sys_no, para1, para2, para3
    movq \sys_no,%rax
    movq \para1,%rdi
    movq \para2,%rsi
    movq \para3,%rdx
    syscall
.endm

# 代码段
.text
# 暴露外部可以使用的函数
.globl _print_string
.globl _print_char
.globl _print_num
.globl _get_char
.globl _get_num

_print_string:          # 声明一个打印字符串的函数，需要两个参数
	# 将字符串的首地址和要打印的长度赋给参数2和参数3
	movq %rsi,%rdx
	movq %rdi,%rsi
	# 将调用号和文件描述符赋给%rax和参数1
	movq $1,%rax
	movq $1,%rdi
	syscall
	ret
_print_char:            # 声明一个用于输出单个字符的函数，需要一个参数
.PCini:                 # 创建新栈，保存原栈
    pushq %rbp
    movq %rsp,%rbp
.PC0:
    # 输出字符压栈，输出，恢复栈
    pushq %rdi
    sys_io $1,$1,%rsp,$1
    popq %rdi
.PCdone:                # 还原栈，返回	
    popq %rbp
    ret
_print_num:             # 声明一个以十进制格式打印数字的函数，需要一个参数
.PNini:                 # 创建新栈，保存原栈
	pushq %rbp
	movq %rsp,%rbp
.PN0:
	movq %rdi,%rax	    # 将要打印的数从参数1赋值给%rax
.PN1:
	# 不停将%rax除10，将余数转换成ascii压栈
	cmpq $0,%rax
	jle .PN2
	movq $0,%rdx
	movq $10,%rdi
	idivq %rdi
	addq $48,%rdx
	pushq %rdx
	jmp .PN1
.PN2:
	# 不停地输出栈中的元素，直到栈为空
	cmp %rsp,%rbp
	je .PNdone
    popq %rdi
    call _print_char
	jmp .PN2
.PNdone:                # 还原栈，返回	
	popq %rbp
	ret
_get_char:              # 声明一个读入单个字符的函数，返回读入的字符
.GCini:                 # 创建新栈，保存原栈
    pushq %rbp
    movq %rsp,%rbp
.GCpre:                 # 在栈中预留输入用的空间
    subq $8,%rsp
.GC0:                   # 输入字符存储到栈顶
    sys_io $0,$0,%rsp,$1
    # 将输入的字符放到rax中返回
    movq (%rsp),%rax
    addq $8,%rsp
.GCdone:
    popq %rbp
    ret
_get_num:               # 声明一个读入一个整形数的函数，返回读入的整形数
.GNini:                 # 创建新栈，保存原栈
    pushq %rbp
    movq %rsp,%rbp
.GNpre:                 # 在栈中预留位置用于存放生成的整形数
    subq $8,%rsp
    movq $0,(%rsp)
.GN0:
    # 不断读入，直到读到的数在ascii码‘0’到‘9’之间
    call _get_char
    cmpq $48,%rax
    jl .GN0
    cmpq $57,%rax
    jg .GN0
.GN1:
    # 不断读入，直到读入的数不在ascii码‘0’到‘9’之间
    cmpq $48,%rax
    jl .GN2
    cmpq $57,%rax
    jg .GN2
    subq $48,%rax       # 读入的数减去48得到真实数字
    movq %rax,%rcx      # 输入数移动到rcx
    movq (%rsp),%rax    # 将之前的数移动到rax
    imulq $10,%rax      # 之前的数乘10
    addq %rcx,%rax      # 将读入的数加到之前的数中
    movq %rax,(%rsp)    # 得到的新数压栈
    call _get_char
    jmp .GN1
.GN2:
    # 返回读入的数字
    movq (%rsp),%rax
    addq $8,%rsp
.GNDone:
    popq %rbp
    ret
