// Design of ALU useful for formal verification. It acts as a golden reference model for DPV or FV.
#include "Hector.h"
#include <stdint.h>

void performAnd(bool size, uint32_t operand1, uint32_t operand2, uint32_t &result, uint8_t &signal) {
  result = operand1 & operand2;
  if(size == 0) {
    result = result & 0x0000ffff;
    if(result == 0x0000ffff) signal += 2;
  }
  else {
    if(result == 0xffffffff) signal += 2;
  }
  if(result == 0) signal += 1;
}

void performOr(bool size, uint32_t operand1, uint32_t operand2, uint32_t &result, uint8_t &signal) {
  result = operand1 | operand2;
  if(size == 0) {
    result = result & 0x0000ffff;
    if(result == 0x0000ffff) signal += 2;
  }
  else {
    if(result == 0xffffffff) signal += 2;
  }
  if(result == 0) signal += 1;
}


void performAdd(bool size, uint32_t operand1, uint32_t operand2, uint32_t &result, uint8_t &signal) {
  int32_t operand1_32bit, operand2_32bit, result_32bit;
  int16_t operand1_16bit, operand2_16bit, result_16bit;
  operand1_32bit = static_cast<int32_t> (operand1);
  operand2_32bit = static_cast<int32_t> (operand2);
  operand1_16bit = static_cast<int16_t> (operand1 & 0x0000ffff);
  operand2_16bit = static_cast<int16_t> (operand2 & 0x0000ffff);

  result_32bit = operand1_32bit + operand2_32bit;
  result_16bit = operand1_16bit + operand2_16bit;
  if(size == 0) {
    result = (static_cast <uint32_t> (result_16bit)) & 0x0000ffff;
    if(operand1_16bit > 0 && operand2_16bit > 0 && result_16bit <= 0) signal += 2;
    if(operand1_16bit < 0 && operand2_16bit < 0 && result_16bit >= 0) signal += 2;
  }
  else {
    result = static_cast <uint32_t> (result_32bit);
    if(operand1_32bit > 0 && operand2_32bit > 0 && result_32bit <= 0) signal += 2;
    if(operand1_32bit < 0 && operand2_32bit < 0 && result_32bit >= 0) signal += 2;
  }
  if(result == 0) signal += 1;
}


void performSub(bool size, uint32_t operand1, uint32_t operand2, uint32_t &result, uint8_t &signal) {
  int32_t operand1_32bit, operand2_32bit, result_32bit;
  int16_t operand1_16bit, operand2_16bit, result_16bit;
  operand1_32bit = static_cast<int32_t> (operand1);
  operand2_32bit = static_cast<int32_t> (operand2);
  operand1_16bit = static_cast<int16_t> (operand1 & 0x0000ffff);
  operand2_16bit = static_cast<int16_t> (operand2 & 0x0000ffff);

  result_32bit = operand1_32bit - operand2_32bit;
  result_16bit = operand1_16bit - operand2_16bit;
  if(size == 0) {
    result = (static_cast <uint32_t> (result_16bit)) & 0x0000ffff;
    if(operand1_16bit >= 0 && operand2_16bit < 0 && result_16bit <= 0) signal += 2;
    if(operand1_16bit < 0 && operand2_16bit >= 0 && result_16bit >= 0) signal += 2;
  }
  else {
    result = static_cast <uint32_t> (result_32bit);
    if(operand1_32bit >= 0 && operand2_32bit < 0 && result_32bit <= 0) signal += 2;
    if(operand1_32bit < 0 && operand2_32bit >= 0 && result_32bit >= 0) signal += 2;
  }
  if(result == 0) signal += 1;
}


void performSatAdd(bool size, uint32_t operand1, uint32_t operand2, uint32_t &result, uint8_t &signal) {
  uint64_t temp_result;
  if(size == 0) {
    temp_result = (operand1 & 0x0000ffff) + (operand2 & 0x0000ffff);
    if(temp_result >> 16 != 0) {
      result = 0x0000ffff;
      signal += 2;
    }
    else {
      result = temp_result & 0x0000ffff;
    }
  }
  else {
    temp_result = static_cast <uint64_t> (operand1) + operand2;
    if(temp_result >> 32 != 0) {
      result = 0xffffffff;
      signal += 2;
    }
    else {
      result = temp_result;
    }
  }
  if(result == 0) signal += 1;
}


void performSatSub(bool size, uint32_t operand1, uint32_t operand2, uint32_t &result, uint8_t &signal) {
  uint64_t temp_result;
  if(size == 0) {
    temp_result = (operand1 & 0x0000ffff) - (operand2 & 0x0000ffff);
    if(temp_result >> 16 != 0) {
      result = 0;
      signal += 2;
    }
    else {
      result = temp_result & 0x0000ffff;
    }
  }
  else {
    temp_result = static_cast <uint64_t> (operand1) - operand2;
    if(temp_result >> 32 != 0) {
      result = 0;
      signal += 2;
    }
    else {
      result = temp_result;
    }
  }
  if(result == 0 && signal == 0) signal += 1;
}


void performMultiply(bool size, uint32_t operand1, uint32_t operand2, uint32_t &result, uint8_t &signal) {
  if(size == 0) {
    result = (operand1 & 0xffff) * (operand2 & 0xffff);
    if(result == 0) signal += 1;
  }
}


void performXor(bool size, uint32_t operand1, uint32_t operand2, uint32_t &result, uint8_t &signal) {
  result = operand1 ^ operand2;
  if(size == 0) {
    result = result & 0x0000ffff;
    if(result == 0x0000ffff) signal += 2;
  }
  else {
    if(result == 0xffffffff) signal += 2;
  }
  if(result == 0) signal += 1;
}


int countB1s(uint32_t B){
  int count = 0;
  while (B != 0)
  {
    count += B%2;
    B = B/2;
  }
  return count;
}


void performComplex(bool size, uint32_t operand1, uint32_t operand2, uint32_t &result, uint8_t &signal){
  uint32_t temp_A;
  uint8_t num_ones;
  if(size == 0){
    operand1 = operand1 & 0x0000ffff;
    operand2 = operand2 & 0x0000ffff;
    temp_A = operand1 << 4;
    num_ones = countB1s(operand2);
    if (num_ones == 16){
      result = temp_A;
      signal+=2;
    }
    else{
      result = temp_A + countB1s(operand2);
    }
  }
  else{
    temp_A = operand1 << 5;
    num_ones = countB1s(operand2);
    if (num_ones == 32)
    {
      result = temp_A;
      signal+=2;
    }
    else{
      result = temp_A + countB1s(operand2);
    }
  }
  if(result == 0) signal+=1;
}


int alu (uint8_t command, bool size, uint32_t operand1, uint32_t operand2, uint32_t &result, uint8_t &signal) 
{
switch(command) {
  case 0: performAnd(size, operand1, operand2, result, signal);
          break;
  case 1: performOr(size, operand1, operand2, result, signal);
          break;
  case 2: performAdd(size, operand1, operand2, result, signal);
          break;
  case 3: performSub(size, operand1, operand2, result, signal);
          break;
  case 4: performSatAdd(size, operand1, operand2, result, signal);
          break;
  case 5: performSatSub(size, operand1, operand2, result, signal);
          break;
  case 6: performMultiply(size, operand1, operand2, result, signal);
          break;
  case 7: performComplex(size, operand1, operand2, result, signal);
  break;
}
return 0;
}

// Function used to bind C++ model with Verilog model. Used as wrapper to be useful in Synopsys VC Formal tool
int DPV_wrapper () {
    uint32_t operand1;
    uint32_t operand2;
    uint8_t command;
    bool size;
    uint32_t result;
    uint8_t signal;
    Hector::registerInput ("in_a", operand1);
    Hector::registerInput ("in_b", operand2);
    Hector::registerInput ("command", command);
    Hector::registerInput ("size", size);
    Hector::registerOutput ("result", result);
    Hector::registerOutput ("signal", signal);

    Hector::beginCapture();
    signal = 0;
    result = 0;
    alu(command, size, operand1, operand2, result, signal);
    Hector::endCapture();
    return 0;
}
