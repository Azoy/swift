// RUN: %target-typecheck-verify-swift

// ok
asm {
  nop
}

asm hello { // expected-error {{expected '{' after 'asm'}}
  mov eax, ecx
  mov ecx, eax
}

asm nop // expected-error {{expected '{' after 'asm'}}

asm {
  mov eax, ecx ; Move the value in the ecx register into the eax register
  mov ecx, eax ; Move the value in the eax register into the ecx register
}

asm {
  mov eax, ecx
  mov ecx, eax
// expected-error@+1 {{expected '}' at the end of 'asm'}}
