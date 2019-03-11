#include<iostream>
#include<vector>
#include<cstdlib>
#include<stdint.h>
#include<fstream>
using namespace std;

class outputBuffer{
private:
  ofstream* output;
  char buffer[1024];
  int top;
public:
  outputBuffer(string filename){
    output=new ofstream(filename,ios::binary);
    top=0;
  }
  void write(int8_t item)
  {

    if(top+1==1024)
    {
      flush();
      top=0;
    }
    buffer[top++]=(char)item;
  }
  void write(int16_t item)
  {
    if(top+2==1024)
    {
      flush();
    }
    buffer[top++]=*((char*)&item);
    buffer[top++]=*((char*)&item+1);
  }
  void  flush()
  {
    output->write(buffer,top);
    top=0;
  }
  void close()
  {
    flush();
      output->close();
  }


};

int main(int argc, char * argv[])
{
  string byteStream=string(argv[1]);
  string shortStream=string(argv[2]);
  outputBuffer outputFileByte(byteStream);
  outputBuffer outputFileShort(shortStream);
  string line;
  vector<string> tokens;
  int16_t* intPtr=new int16_t();
  char* charPtr;
  int16_t prev[2000];
  int prevTop=0;

  int16_t shortBuffer[2000];
  int shortTop=0;

  int8_t byteBuffer[2000];
  int byteTop=0;


  int16_t tmp;
  int8_t tmp2;
  bool first=true;
  int count=0;
  int sign=1;
  for(int i=0;i<2000;i++)
  {
    prev[i]=0;
  }
  while(getline(cin,line))
  {
    line+='\n';
    //    cout<<line<<endl;
    for(auto c:line)
      {
	if(c==','||c=='\n'){
	  *intPtr*=sign;
	//	cout<<*intPtr<<endl;
	  tmp=*intPtr;
	  *intPtr-=prev[prevTop];
	  prev[prevTop++]=tmp;
	  *intPtr=*intPtr>>1;
	if(*intPtr>127 || *intPtr<-126)
	  {
	    byteBuffer[byteTop++]=-127;
	    shortBuffer[shortTop++]=*intPtr;
	  }
	else{
	  byteBuffer[byteTop++]=*intPtr;
	}
	sign=1;
	*intPtr=0;
      }
      else{
	if(c=='-'){
	  sign=-1;
	}
	else{
	  *intPtr=*intPtr*10+((int)c-48);
	}
      }

      }
    tmp=prevTop;
    outputFileShort.write(tmp);

    for(int i=0;i<shortTop;i++)
      {
	tmp=shortBuffer[i];
	outputFileShort.write(tmp);
      }
    for(int i=0;i<byteTop;i++)
      {
	tmp2=byteBuffer[i];
	outputFileByte.write(tmp2);
      }
    byteTop=0;
    shortTop=0;
    prevTop=0;
  }
  outputFileByte.close();
  outputFileShort.close();

}
