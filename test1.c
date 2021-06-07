#include <stdio.h>
#include <stdlib.h>
#include <malloc.h>
#include <memory.h>
#define LOG_PRIORITY 40 
#define debug(pri,...) if(pri==LOG_PRIORITY) {printf(__VA_ARGS__);printf("\n");}

// [equal , ]
// or 
// [op , =]
#define LOGLV 0

FILE* fp;
// print and write to file
#define print_delegate(...) {printf(__VA_ARGS__);fp = fopen( "out_file.txt", "a+" );fprintf(fp, __VA_ARGS__);fclose(fp);}


typedef struct table_item {
    char w_name[20];
    int w_kind;// 1 identifier 2 number const 3 char const
    int w_type;
    int w_val;
    int w_addr;
    struct table_item *item_next;
};
struct table_item *table_head, *table_tail;


int main() {
    char sentance_input[200];
    char word_token[20];
    char next_c;
    int w_forward = 0, w_next = 0;   //w_forward 单词开头，w_next当前光标
    int w_state = 0;
    int x_num = 0, id_x = 0;
    // clear file 
    fp = fopen( "out_file.txt", "w" );fprintf(fp, "");fclose(fp);
    
    // print_delegate("hello %s","who i am");

    char w_keyword[][8] = {"if", "else", "while", "do", "int", "float"};

    FILE *fp_soure;
    table_head = (struct table_item *) malloc(sizeof(struct table_item));
    table_tail = (struct table_item *) malloc(sizeof(struct table_item));

    table_tail = table_head = NULL;
    fp_soure = fopen("testcase.txt", "r+");

//    printf("%d",fp_soure);
    if (fp_soure != NULL) {
        memset(sentance_input, 0x00, sizeof(char) * 200);

        //reading all lines
        //一次读一行
        while (EOF != fscanf(fp_soure, "%[^\n]\n", sentance_input)) { //%*c
            // printf("input is ... %s\n", sentance_input);

            w_next = 0;
            w_forward = 0;
            w_state = 0;
            x_num = 0;

            while (1) {
                switch (w_state) {
                    case 0:
                    // 新的token 状态

                        //没有读入任何内容，空串状态

                        //删除空串

                        // deleting the backspaces in front of line
                        while ((next_c = sentance_input[w_next]) == ' ' || next_c == '\t') {// || next_c=='\t'
                            w_next++;
                            w_forward++;
                            //forward = next
                        }
                        memset(word_token, 0x00, sizeof(char) * 20);
                        x_num = 0;
// -
                        // processing the digits
                        if (isdigit(next_c)) {

                            //长度测试
                            while ((next_c != ' ') && (isdigit(next_c) || next_c == '.')) { //
                                w_next++;
                                next_c = sentance_input[w_next];
                            }

                            if (next_c == ' ' || !(isalpha(next_c)))
                                w_next--;

                            //单词偏移地址
                            x_num = 0;
                            while (w_forward <= w_next) {
                                //把对应单词拷贝过来
                                word_token[x_num] = sentance_input[w_forward];
                                w_forward++;
                                x_num++;
                            }
                            word_token[w_forward + 1] = '\0';

                            //数字开头的肯定是数字
                            print_delegate("token is [ digits ,%s]\n", word_token);

                            w_state = 0;
                            w_next = w_forward;
                            break;
                        }
                        // -
                        // processing the id
                        if (isalpha(next_c)) {

                            //长度测试
                            while ((next_c != ' ') && (isalpha(next_c) || isalnum(next_c) || next_c == '_')) {
                                w_next++;
                                next_c = sentance_input[w_next];
                            }

                            if (next_c == ' ' || !(isalpha(next_c)))
                                w_next--;

                            x_num = 0;
                            while (w_forward <= w_next) {
                                word_token[x_num] = sentance_input[w_forward];
                                w_forward++;
                                x_num++;
                            }
                            word_token[w_forward + 1] = '\0';
                            

                            for (int i = 0; i < 6; i++) {
                                if (strcmp(word_token, w_keyword[i]) == 0) {

                                    //是关键字
                                    print_delegate("token is [ keyword ,%s]\n", word_token);
                                    id_x = 1;//keyword not in table

                                    break;
                                }
                            }
                            //是标识符
                            if (id_x == 0)
                                print_delegate("token is [ id ,%s]\n", word_token);
                            w_state = 0;
                            id_x = 0;
                            w_next = w_forward;
                            break;
                        }
                        // processing the relation operators, the calculating operators and the other operators.
// -
                        //直接状态
                        switch (next_c) {
                            case '<':
                                w_state = 1;
                                break;
                            case '=':
                                w_state = 5;
                                break;
                            case '>':
                                w_state = 6;
                                break;
                            case '+':
                                w_state = 9;
                                break;
                            case '-':
                                w_state = 10;
                                break;
                            case '*':
                                w_state = 11;
                                break;
                            case '/':
                                w_state = 12;
                                break;
                            case '(':
                                w_state = 13;
                                break;
                            case ')':
                                w_state = 14;
                                break;
                            case ';':
                                // print_delegate("error at %c",next_c);
                                w_state = 15;
                                break;
                            case '\'':
                                w_state = 16;
                                break;
                            case '\0':
                                w_state = 100;
                                //sentance_input="";
                                memset(sentance_input, 0x00, sizeof(char) * 200);
                                break;
                            default :
                                print_delegate("error at %c",next_c);
                                printf("\nerror info : %c\n",next_c);

                                w_next+=1;
                                break;
                        }

                        //printf("state is %d\n",w_state);
                        break;

                    case 1:
//                        <
                        w_next++;
                        next_c = sentance_input[w_next];
                        switch (next_c) {
                            case '=':
                                w_state = 2;
                                break;
                            case '>':
                                w_state = 3;
                                break;
                            default:
                                w_state = 4;
                                break;
                        }

                        break;

                    case 5:
                        w_next++;
                        next_c = sentance_input[w_next];
                        switch (next_c) {
                            case '=':
                                w_state = 21;
                                break;
                            default:
                            //read new tokens
                                w_forward+=1;
                                w_state = 0;
                                // w_next--;
                                print_delegate("token is [ op ,%s]\n", "=");
                                break;
                        }
                        break;
                    case 6:
                        w_next++;
                        next_c = sentance_input[w_next];
                        switch (next_c) {
                            case '=':
                                w_state = 7;
                                break;
                            default:
                                w_state = 8;
                                break;
                        }

                        break;

                    case 2:
                        x_num = 0;  //单词的偏移地址
                        while (w_forward <= w_next) {
                            word_token[x_num] = sentance_input[w_forward];
                            w_forward++;
                            x_num++;
                        }
                        word_token[w_forward + 1] = '\0';
                        print_delegate("token is [ op ,%s]\n", word_token);
                        w_state = 0;
                        w_next = w_forward;
                        break;
                    case 3:

                        x_num = 0;
                        while (w_forward <= w_next) {
                            word_token[x_num] = sentance_input[w_forward];
                            w_forward++;
                            x_num++;
                        }
                        word_token[w_forward + 1] = '\0';
                        print_delegate("token is [ op ,%s]\n", word_token);
                        w_state = 0;
                        w_next = w_forward;
                        break;
                    case 4:
                        w_next--;

                        x_num = 0;
                        while (w_forward <= w_next) {
                            word_token[x_num] = sentance_input[w_forward];
                            w_forward++;
                            x_num++;
                        }
                        word_token[w_forward] = '\0';
                        print_delegate("token is [ op ,%s]\n", word_token);
                        w_state = 0;
                        w_next = w_forward;
                        break;
                    
                    case 7:
                        x_num = 0;
                        while (w_forward <= w_next) {
                            word_token[x_num] = sentance_input[w_forward];
                            w_forward++;
                            x_num++;
                        }
                        word_token[w_forward] = '\0';
                        print_delegate("token is [ op ,%s]\n", word_token);
                        w_state = 0;
                        w_next = w_forward;
                        break;
                    case 8:
                        w_next--;
                        x_num = 0;
                        while (w_forward <= w_next) {
                            word_token[x_num] = sentance_input[w_forward];
                            w_forward++;
                            x_num++;
                        }
                        word_token[w_forward] = '\0';
                        print_delegate("token is [ op ,%s]\n", word_token);
                        w_state = 0;
                        w_next = w_forward;
                        break;
                     case 21:
                        x_num = 0;
                        while (w_forward <= w_next) {
                            word_token[x_num] = sentance_input[w_forward];
                            w_forward++;
                            x_num++;
                        }
                        word_token[w_forward] = '\0';
                        print_delegate("token is [ op ,%s]\n", word_token);
                        w_state = 0;
                        w_next = w_forward;
                        break;
                    case 9:
                    case 10:
                    case 11:
                    case 12:
                        x_num = 0;
                        while (w_forward <= w_next) {
                            word_token[x_num] = sentance_input[w_forward];
                            w_forward++;
                            x_num++;
                        }
                        word_token[w_forward] = '\0';
                        print_delegate("token is [ op ,%s]\n", word_token);
                        w_state = 0;
                        w_next = w_forward;
                        break;
                    case 13:
                    case 14:
                    case 15:
                    case 16:
                        x_num = 0;
                        while (w_forward <= w_next) {
                            word_token[x_num] = sentance_input[w_forward];
                            w_forward++;
                            x_num++;
                        }
                        word_token[w_forward] = '\0';
                        print_delegate("token is [ divider ,%s]\n", word_token);
                        w_state = 0;
                        w_next = w_forward;
                        break;
                    
                    case 100:
                        w_state=0;
                        break;

                    default:
                        w_state=0;
                        w_next+=1;
                        break;
                }
                // if(w_state==15)break;
                if (w_state == 100) break;
            }
        }
        fclose(fp_soure);
    } else {
        printf("open file error!\n");
    }
    print_delegate("token is [ divider ,$]\n");
    return 0;
}
