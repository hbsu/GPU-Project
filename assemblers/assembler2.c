#include <stdio.h>
#include <string.h>
#include <stdlib.h>

//Type assembly Commands and it will convert to text file.
//Type "regInit" to get all 8 registers initialized to zero.
//Use "location: xx" to specify a location for a command.
//Example:
//location: 5
//ADD R5, R5, R5
//will output:

//preload_addr = 8'h05; //This line specifies the address of the memory
//preload_data = 16'b0001110110110100; // ADD R5, R5, R5, the data which will be stored in memory location
//#10; //Let one clock cycle pass

//To use the testbench, copy and paste the assembled code AFTER the preload_we
//



int reg_to_int(char *reg) {
    if (reg[0] == 'R' || reg[0] == 'r')
        return atoi(&reg[1]);
    return 0;
}

void reg_to_binstr(int val, char *out) {
    for (int i = 2; i >= 0; --i)
        out[2 - i] = ((val >> i) & 1) ? '1' : '0';
    out[3] = '\0';
}

char* imm_to_bin(int imm, int width) {
    static char bin[20];
    if (imm < 0) imm = (1 << width) + imm;
    for (int i = width - 1; i >= 0; --i)
        bin[width - 1 - i] = ((imm >> i) & 1) ? '1' : '0';
    bin[width] = '\0';
    return bin;
}

void assemble(char *line, int addr) {
    char op[10], r1[10], r2[10], r3[10];
    int num = sscanf(line, "%s %s %s %s", op, r1, r2, r3);

    char binary[17] = "";
    char regA[4], regB[4], regC[4];
    int imm;

    if (strcmp(op, "ADD") == 0 || strcmp(op, "SUB") == 0 ||
        strcmp(op, "MUL") == 0 || strcmp(op, "AND") == 0) {
        char *opcode = strcmp(op, "ADD") == 0 ? "0001" :
                       strcmp(op, "SUB") == 0 ? "0010" :
                       strcmp(op, "MUL") == 0 ? "0011" : "0100";
        strcat(binary, opcode);

        if (r3[0] == '#') {
            strcat(binary, "0");
            reg_to_binstr(reg_to_int(r1), regA);
            reg_to_binstr(reg_to_int(r2), regB);
            imm = atoi(&r3[1]);
            strcat(binary, regA);
            strcat(binary, regB);
            strcat(binary, imm_to_bin(imm, 5));
        } else {
            strcat(binary, "1");
            reg_to_binstr(reg_to_int(r1), regA);
            reg_to_binstr(reg_to_int(r2), regB);
            reg_to_binstr(reg_to_int(r3), regC);
            strcat(binary, regA);
            strcat(binary, regB);
            strcat(binary, regC);
            strcat(binary, "00");
        }

    } else if (strcmp(op, "NOT") == 0) {
        strcat(binary, "01010");
        reg_to_binstr(reg_to_int(r1), regA);
        reg_to_binstr(reg_to_int(r2), regB);
        strcat(binary, regA);
        strcat(binary, regB);
        strcat(binary, "00000");

    } else if (strcmp(op, "ST") == 0 || strcmp(op, "LD") == 0 ||
               strcmp(op, "STI") == 0 || strcmp(op, "LDI") == 0 ||
               strcmp(op, "BRZ") == 0 || strcmp(op, "BRN") == 0) {
        char *opcode = strcmp(op, "ST") == 0 ? "0110" :
                       strcmp(op, "LD") == 0 ? "0111" :
                       strcmp(op, "STI") == 0 ? "1010" :
                       strcmp(op, "LDI") == 0 ? "1011" :
                       strcmp(op, "BRZ") == 0 ? "1110" : "1111";
        strcat(binary, opcode);
        reg_to_binstr(reg_to_int(r1), regA);
        imm = atoi(&r2[1]);
        strcat(binary, regA);
        strcat(binary, imm_to_bin(imm, 9));

    } else if (strcmp(op, "STR") == 0 || strcmp(op, "LDR") == 0) {
        char *opcode = strcmp(op, "STR") == 0 ? "1000" : "1001";
        strcat(binary, opcode);
        reg_to_binstr(reg_to_int(r1), regA);
        reg_to_binstr(reg_to_int(r2), regB);
        strcat(binary, regA);
        strcat(binary, regB);
        strcat(binary, "000000");

    } else if (strcmp(op, "JMP") == 0) {
        strcat(binary, "1100000");
        reg_to_binstr(reg_to_int(r1), regA);
        strcat(binary, regA);
        strcat(binary, "000000");

    } else if (strcmp(op, "RET") == 0) {
        strcpy(binary, "1101000000000000");

    } else if (strcmp(op, "NOP") == 0) {
        strcpy(binary, "0000000000000000");
    } else {
        printf("// Unknown instruction: %s\n", line);
        return;
    }

    printf("bootloadAddress = 8'h%02X;\n", addr);
    printf("bootloadIn = 16'b%s; // %s\n", binary, line);
    printf("#10;\n\n");
}

void emit_reg_init(int *addr_ptr) {
    int addr = *addr_ptr;
    for (int i = 0; i < 8; i++) {
        char bin[17] = "01000"; // AND opcode + I=0
        char reg[4];
        reg_to_binstr(i, reg);
        strcat(bin, reg); // dest
        strcat(bin, reg); // src
        strcat(bin, "00000"); // imm5 = 0

        printf("// AND R%d, R%d, #0\n", i, i);
        printf("bootloadAddress = 8'h%02X;\n", addr);
        printf("bootloadIn = 16'b%s; // AND R%d, R%d, #0\n", bin, i, i);
        printf("#10;\n\n");

        addr++;
    }
    *addr_ptr = addr; // update caller's address counter
}

int main(int argc, char *argv[]) {
    char line[100];
    int addr = 0;

    if (argc == 2) {
        addr = atoi(argv[1]);  // optional initial address
        printf("// Starting at address: 0x%02X\n", addr);
    }

    printf("// Enter assembly lines (type END to finish):\n");

    while (1) {
        printf("// ");
        fgets(line, sizeof(line), stdin);
        line[strcspn(line, "\n")] = 0;

        if (strcmp(line, "END") == 0) break;

        if (strncmp(line, "location:", 9) == 0) {
            int new_addr = atoi(&line[9]);
            addr = new_addr;
            printf("// Location updated to 0x%02X\n\n", addr);
            continue;
        }

        if (strcmp(line, "regInit") == 0) {
            emit_reg_init(&addr);
            continue;
        }

        assemble(line, addr++);
    }


    return 0;
}
