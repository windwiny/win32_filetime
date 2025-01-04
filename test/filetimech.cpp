
/* UTF-8 BOM */
// g++ filetimech.cpp

#include <stdio.h>
#include <wchar.h>
#include <iostream>
#include "Windows.h"

const int SZ = 25;

void st2str(LPSYSTEMTIME st, char* out, size_t len) {
    int i = sprintf_s(out, len, "%04d-%02d-%02d %02d:%02d:%02d.%-03d", st->wYear, st->wMonth, st->wDay, st->wHour, st->wMinute, st->wSecond, st->wMilliseconds);
    i < len ? out[i] = 0 : out[len - 1] = 0;
}

int main()
{
    std::cout << "Hello World! 111\n";

    LPCWSTR  fn = L"g:\\k2\\c1.zip";
    HANDLE hf1= CreateFileW(fn, GENERIC_READ, FILE_SHARE_READ | FILE_SHARE_WRITE,
        NULL, OPEN_EXISTING, FILE_FLAG_BACKUP_SEMANTICS, 0);


    //LPCSTR  fn = "g:\\k2\\c1.zip";
    //HANDLE hf1 = CreateFileA(fn, GENERIC_READ, FILE_SHARE_READ | FILE_SHARE_WRITE,
    //    NULL, OPEN_EXISTING, FILE_FLAG_BACKUP_SEMANTICS, 0);


   if (hf1 == INVALID_HANDLE_VALUE) {
       std::cout << "CreateFileW failed " << fn<<std::endl;
       return -1;
   }
   FILETIME tc, ta, tm;

   BOOL res= GetFileTime(hf1, &tc, &ta, &tm);

   if (res != TRUE) {
       std::cout << "GetFileTime failed\n";
       return -2;
   }

   LARGE_INTEGER sz;
   res = GetFileSizeEx(hf1, &sz);

   if (res != TRUE) {
       std::cout << "GetFileSizeEx failed\n";
       return -3;
   }


   SYSTEMTIME stc, sta, stm;

   BOOL r1 = FileTimeToSystemTime(&tc, &stc);
   BOOL r2 = FileTimeToSystemTime(&ta, &sta);
   BOOL r3 = FileTimeToSystemTime(&tm, &stm);

   wprintf(L"fn: \"%ws\" \n", fn);

   char ac[SZ], aa[SZ], am[SZ];
   st2str(&stc, ac, SZ);
   st2str(&sta, aa, SZ);
   st2str(&stm, am, SZ);
 
   printf("%s\n%s\n%s\n", ac, aa, am);
}
