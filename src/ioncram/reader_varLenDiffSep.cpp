#include<iostream>
#include<vector>
#include<cstdlib>
#include<stdint.h>
#include<fstream>
#include <math.h>

using namespace std;
int main(int argc, char * argv[])
{
  string byteStream=string(argv[1]);
  string shortStream=string(argv[2]);
  int binning=atoi(argv[3]);
  ifstream inputFileByte(byteStream,ios::binary);
  ifstream inputFileShort(shortStream,ios::binary);
  string line;
  vector<string> tokens;
  int16_t* intPtr=new int16_t();
  int16_t tmp;
  int16_t Novalues;
  int16_t prev[2000];
  int prevTop=0;
  int8_t tmp2;
  int count=0;
  for(int i=0;i<2000;i++)
  {
    prev[i]=0;
  }
  while(inputFileShort.read((char*)&Novalues,sizeof(Novalues)))
  {
  //  count++;
    if(Novalues==0 || Novalues==1)
    {
      continue;
    }
    if(inputFileByte.eof() && inputFileShort.eof()){
      break;
    }
    if(count ==10000)
    {
      count=0;
      for(int i=0;i<2000;i++)
      {
        prev[i]=0;
      }
    }



    for(int i=0;i<Novalues;i++)
    {
      inputFileByte.read((char*)&tmp2,sizeof(tmp2));

      tmp=0;
      if(tmp2==-127){
        inputFileShort.read((char*)&tmp,sizeof(tmp));
      }
      else{
        tmp=tmp2;
      }
      //tmp*=2;
      //prev[prevTop]*=binning;
      prev[prevTop]+=tmp;
      

      cout<<prev[prevTop]*binning;
      prevTop++;
      if(i!=Novalues-1)
      {
        cout<<",";
      }
    }
    cout<<endl;
    prevTop=0;


  }
  inputFileByte.close();
  inputFileShort.close();
}
