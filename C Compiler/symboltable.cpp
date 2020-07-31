#include<iostream>
#include<string>
#include<stdlib.h>
#include<stdio.h>
#include<string>
#include<string.h>
#include<vector>
using namespace std;


class Extra_var
{
public:
    string func_ret_type;
    string ID_type;
    string var_type;
    string concatenator;
    string array_size;
    string array_index;
    string assm_code;
    string carr1;
    bool is_func_defined;
    bool is_func_declared;
    bool is_function;
    vector< pair<string,string> >var_declared_list;
    vector < pair<string,string> >func_param_list;
    vector<string>modfd_param_list;
    string join_string(string a)
    {
         return concatenator.append(a);
    }

};

class SymbolInfo
{
    string Name;
    string Type;
    SymbolInfo* next;


public:
    Extra_var extra_var;

    SymbolInfo()
    {
        this->Name = "";
        this->Type = "";
        extra_var.array_index = "";
        extra_var.array_size = "";
        extra_var.ID_type = "";
        extra_var.is_func_declared = false;
        extra_var.is_func_defined = false;
        extra_var.var_type = "";\
        extra_var.func_ret_type = "";
        extra_var.is_function = false;
    }

    SymbolInfo(string name, string type)
    {
        this->Name = name;
        this->Type = type;
        extra_var.array_index = "";
        extra_var.array_size = "";
        extra_var.ID_type = "";
        extra_var.is_func_declared = false;
        extra_var.is_func_defined = false;
        extra_var.var_type = "";
        extra_var.func_ret_type = "";
        extra_var.is_function = false;
    }

    string getName()
    {
        return Name;
    }

    void  setName(string symbolname)
    {
        Name = symbolname;
    }

    string getType()
    {
        return Type;
    }

    void setType(string symboltype)
    {
        Type = symboltype;
    }

    SymbolInfo* getnext()
    {
        return next;
    }

    void setnext(SymbolInfo* p)
    {
        next = p;
    }
};

class ScopeTable
{
    int sizeOfTable;
    int TableId;
    ScopeTable* parentScope;

    /// An array of SymbolInfo pointers for the main array of the Scope table with chaining
    SymbolInfo **Table;

public:
    ScopeTable(int n,int counter)
    {
        sizeOfTable = n;
        TableId = counter;
        parentScope = 0;

        ///Allocating space for an array of pointers
        Table = new SymbolInfo*[sizeOfTable];

        for(int i=0; i<sizeOfTable; i++)
        {
            Table[i] = new SymbolInfo;
            Table[i]->setName("");
            Table[i]->setType("");
            Table[i]->setnext(0);
        }
    }

    ScopeTable* getparentScope()
    {
        return parentScope;
    }
    void setparentScope(ScopeTable* p)
    {
        parentScope = p;
    }
    int getTableID()
    {
         return TableId;
    }

    int HashFunc(string key)
    {
        int i=1,sum=(int)key[0];

        while( i<key.length())
        {
            sum ^= (sum<< 5) + (sum >> 2) + (int)key[i];
            i++;
        }

        return abs(sum%sizeOfTable);
    }

    bool Insert(string key, string value)
    {
        int index = -1;

        index = HashFunc(key);

        ///if the indexed node is empty
        if(Table[index]->getName() == "" )
        {

            Table[index]->setName(key);
            Table[index]->setType(value);

            ///cout<<"Inserted in ScopeTable# "<<TableId<<" at position "<< index <<", "<< "0"<<endl;
            ///cout<<endl;

            return true;

        }
        else ///collision  occurred
        {
            ///checking here for duplicates
            SymbolInfo* head = Table[index];

            ///if initial node is the duplicate one
            if(head->getnext() == 0 && head->getName() == key)
            {
                ///cout<<"Symbol with the same name "<<"< "<<head->getName()<<" >"<<" already exists"<<endl;
                ///cout<<endl;
                return false;

            }
            else
            {
                ///The duplicate one may be further down the chain
                while(head!=0)
                {

                    if(head->getName() == key)
                    {
                        ///cout<<"Symbol with the same name "<<"< "<<head->getName()<<" >"<<" already exists"<<endl;
                        ///cout<<endl;
                        return false;
                    }

                    head = head->getnext();
                }
            }
            ///if duplicate is not found, we insert in the chain to resolve collision

            int j =0;

            SymbolInfo* newNode = new SymbolInfo;
            newNode->setName(key);
            newNode->setType(value);
            newNode->setnext(0);

            head = Table[index];

            while(head->getnext() != 0)
            {
                head = head->getnext();
                j++;

            }

            head->setnext(newNode);
            ///cout<<"Inserted in ScopeTable# "<<TableId<<" at position "<< index <<", "<< j+1<<endl;
            ///cout<<endl;

            return true;

        }
    }

    bool Insertmodified(SymbolInfo* s)
    {
        string key = s->getName();
        string value  = s->getType();
        int index = -1;

        index = HashFunc(key);

        ///if the indexed node is empty
        if(Table[index]->getName() == "" )
        {

            Table[index] = s;
            ///cout<<"Inserted in ScopeTable# "<<TableId<<" at position "<< index <<", "<< "0"<<endl;
            ///cout<<endl;

            return true;

        }
        else ///collision  occurred
        {
            ///checking here for duplicates
            SymbolInfo* head = Table[index];

            ///if initial node is the duplicate one
            if(head->getnext() == 0 && head->getName() == key)
            {
                ///cout<<"Symbol with the same name "<<"< "<<head->getName()<<" >"<<" already exists"<<endl;
                ///cout<<endl;
                return false;
            }
            else
            {
                ///The duplicate one may be further down the chain
                while(head!=0)
                {

                    if(head->getName() == key)
                    {
                        ///cout<<"Symbol with the same name "<<"< "<<head->getName()<<" >"<<" already exists"<<endl;
                        ///cout<<endl;
                        return false;
                    }

                    head = head->getnext();
                }
            }

            ///if duplicate is not found, we insert in the chain to resolve collision
            int j =0;
            head = Table[index];

            while(head->getnext() != 0)
            {
                head = head->getnext();
                j++;

            }

            s->setnext(0);
            head->setnext(s);
            ///cout<<"Inserted in ScopeTable# "<<TableId<<" at position "<< index <<", "<< j+1<<endl;
            ///cout<<endl;
            return true;

        }
    }

    SymbolInfo* LookUp(string key)
    {
        SymbolInfo* result;

        int index = -1;

        index = HashFunc(key);


        SymbolInfo *head = Table[index];

        int j = 0;


        ///starting from head node, we search down the chain to find the value we are looking for
        while(head!=0)
        {
            if(head->getName() == key)
            {
                result = head;
                ///cout<<"Found in ScopeTable# "<<TableId<<" at position "<<index<<" , "<<j<<endl;
                ///cout<<endl;
                return result;
            }

            head = head->getnext();
            j++;
        }

        ///When this block is entered it means that the value is not found in the table
        if(head == 0)
        {
            return 0;
        }

    }

    bool Delete(string key)
    {
        int index = -1;

        index = HashFunc(key);

        SymbolInfo *head = Table[index];
        SymbolInfo *p;
        SymbolInfo *q;

        ///the key that I want to search which leads me to an empty index
        if(Table[index]->getName() == "")
        {
            ///cout<<key<<" Not Found"<<endl<<endl;
            return false;
        }
        else if(Table[index]->getName() == key && Table[index]->getnext()!=0) ///If the key I want to delete is the first node of the chain
        {
            SymbolInfo* temp = Table[index];
            Table[index] = Table[index]->getnext();

            ///cout<<"Found in ScopeTable# "<<TableId<<" at position "<<index<<" , 0"<<endl;
            ///cout<<endl;
            ///cout<<"Deleted entry at "<<index<<" , 0"<<" from current scope table"<<endl;
            ///cout<<endl;

            temp->setnext(0);
            delete temp->getnext(); //deleting next pointer
            delete temp;

            return true;
        }
        else if(Table[index]->getName() == key && Table[index]->getnext() == 0) ///If the key I want to search is the only member and there is no chain
        {
            Table[index]->setName("");
            Table[index]->setType("");

            ///cout<<"Found in ScopeTable# "<<TableId<<" at position "<<index<<" , 0"<<endl;
            ///cout<<endl;
            ///cout<<"Deleted entry at "<<index<<" , 0"<<" from current scope table"<<endl;
            ///cout<<endl;

            return true;
        }
        else ///the value is in somewhere along the chain
        {
            p = Table[index];
            q = Table[index]->getnext();
            int j = 0;

            while(q!=0 && q->getName()!=key)
            {
                p = q;
                q = q->getnext();
                j++;
            }

            if(q!=0)
            {
                p->setnext(q->getnext());
                //deleting next pointer
                q->setnext(0);
                delete q->getnext();
                delete q;

                ///cout<<"Found in ScopeTable# "<<TableId<<" at position "<<index<<" , "<<j+1<<endl;
                ///cout<<endl;
                ///cout<<"Deleted entry at "<<index<<" , "<<j+1<<" from current scope table"<<endl;
                ///cout<<endl;

                return true;
            }
            else
            {
                ///cout<<key<<" Not Found"<<endl;
                ///cout<<endl;
                return false;
            }
        }
    }

    void print(FILE* f)
    {
        SymbolInfo *p;

        //cout<<"ScopeTable # "<<TableId<<endl;
        fprintf(f,"ScopeTable # %d\n",TableId);

        for(int i =0; i<sizeOfTable; i++)
        {
            if(Table[i]->getnext() == 0)
            {
                //cout<<i;
                //cout<<" ";
                //cout<<"-->";
                //cout<<" ";
                if(Table[i]->getName()!="")
                {
                    //cout<<"< "<<Table[i]->getName();
                    //cout<<" : ";
                    //cout<<Table[i]->getType()<<">";
                    fprintf(f,"%d --> ",i);
                    fprintf(f,"< %s : %s>",Table[i]->getName().c_str(),Table[i]->getType().c_str());
                    fprintf(f,"\n");

                }



            }
            else
            {
                //cout<<i;
                //cout<<" ";
                //cout<<"-->";
                //cout<<" ";
                fprintf(f,"%d --> ",i);
                p = Table[i];

                while(p != 0)
                {
                    //cout<<"< "<<p->getName();
                    //cout<<" : ";
                    //cout<<p->getType()<<">";
                    //cout<<"  ";
                    fprintf(f,"< %s : %s>  ",p->getName().c_str(),p->getType().c_str());
                    p = p->getnext();

                }

                fprintf(f,"\n");
            }

        }

   fprintf(f,"\n");

    }

    void DeleteAll()
    {
        for(int i =0; i<sizeOfTable; i++)
        {
            SymbolInfo* temp = Table[i];

            while(temp->getName()!="")
            {
                Delete(temp->getName());
                temp = Table[i];
            }
        }
    }

    /*void InsertAndPrint(string key,string value)
    {

    }*/

    ~ScopeTable()
    {
        ///cout<<"calling Destructor of current scope"<<endl<<endl;

        this->DeleteAll();

        for(int i =0; i<sizeOfTable; i++)
        {
            delete Table[i]->getnext(); //deleting next pointer
            delete Table[i];
        }

        delete[] Table;

    }


};




///This method only prints the non empty buckets
/*void ScopeTable::InsertAndPrint(string key,string value)
{


    if(Insert(key,value) == true)
    {
        SymbolInfo* p;

        ///cout<<"ScopeTable # "<<TableId<<endl;
        fprintf(logs,"ScopeTable # %d\n",TableId);
        for(int i = 0; i<sizeOfTable; i++)
        {
            if(Table[i]->getName()!="")
            {
                ///cout<<i;
                ///cout<<" ";
                ///cout<<"-->";
                ///cout<<" ";
                fprintf(logs,"%d--> ",i);

                p = Table[i];

                while(p != 0)
                {
                    ///cout<<"< "<<p->getName();
                    ///cout<<" : ";
                    ///cout<<p->getType()<<">";
                    ///cout<<"  ";
                    fprintf(logs,"<%s : %s> ",p->getName().c_str(),p->getType().c_str());

                    p = p->getnext();
                }

                ///cout<<endl;
                fprintf(logs,"\n");


            }
        }

        ///cout<<endl;
        fprintf(logs,"\n");


    }


}*/


class SymbolTable
{
    ScopeTable* currentScope;
    int tableSize;
    int counter;

public:

    SymbolTable(int n)
    {
        counter = 1;
        tableSize = n;
        ScopeTable* FirstScope = new ScopeTable(n,counter);
        currentScope = FirstScope;
    }

    ScopeTable* getcurrentScope()
    {
        return currentScope;
    }

    void setcurrentScope(ScopeTable* p)
    {
        currentScope = p;
    }

    void EnterScope()
    {
        counter++;
        //cout<<"in scope table "<<counter<<endl;
        ScopeTable* newScope = new ScopeTable(tableSize,counter);
        //cout<<"New ScopeTable with Id "<<newScope->getTableID()<<" created."<<endl;
        //fprintf(f,"New ScopeTable with Id %d created\n",newScope->getTableID());
        ScopeTable* temp;
        temp = currentScope;
        currentScope = newScope;
        currentScope->setparentScope(temp);
    }

    void ExitScope()
    {
        ScopeTable* temp;
        //this->counter--;
        temp = currentScope;
        currentScope = temp->getparentScope();
        ///cout<<"ScopeTable with ID "<<temp->getTableID()<<" removed"<<endl<<endl;
        //fprintf(f,"ScopeTable with ID %d removed\n",temp->getTableID());
        delete temp;
    }

    bool Insert(string Name, string Type)
    {
        if(currentScope->Insert(Name,Type)) return true;
        return false;
    }

    bool Remove(string Name)
    {
         if(currentScope->Delete(Name)) return true;
        return false;
    }

    SymbolInfo* LookUp(string Name)
    {
        SymbolInfo* result;
        ScopeTable* temp;
        temp = currentScope;

        while(temp!=0)
        {
            result = temp->LookUp(Name);

            if(result!=0) return result;
            else temp = temp->getparentScope();

        }

        ///cout<<Name<<" Not Found"<<endl<<endl;
        return 0;
    }


    //a function for looking in current scope in symbol table
    SymbolInfo* currentScopeLookUp(string Name)
    {
        SymbolInfo* result;

        result = currentScope->LookUp(Name);

        if(result!=0) return result;
        return 0;
    }



    void printCurrentScope(FILE* f)
    {
        currentScope->print(f);
    }

    void printAll(FILE* f)
    {
        ScopeTable* temp;
        temp = currentScope;

        while(temp != 0)
        {
            temp->print(f);
            temp = temp->getparentScope();
        }
    }
    //void InsertMod(string Name, string Type);
    ~SymbolTable()
    {
        ScopeTable* temp1 = currentScope;
        ScopeTable* temp2;

        while(temp1!=0)
        {
            temp2 = temp1->getparentScope();
            temp1->~ScopeTable();
            temp1 = temp2;
        }

        delete temp1;
        delete temp2;
    }

    bool Insertmodified(SymbolInfo* s)
    {
        return currentScope->Insertmodified(s);
    }

    int getCurrScopeID()
    {
      return currentScope->getTableID();
    }

    /* this function returns the ID of the current scope by searching an ID*/
    int IDlookUpWithParam(string Name)
    {
      SymbolInfo* result;
      ScopeTable* temp;
      temp = currentScope;

      while(temp!=0)
      {

          result = temp->LookUp(Name);

          if(result!=0) return temp->getTableID();
          else temp = temp->getparentScope();

      }

      //cout<<Name<<" Not Found"<<endl<<endl;
      return -1;
    }


};



/*/void SymbolTable::InsertMod(string Name, string Type)
{
    currentScope->InsertAndPrint(Name,Type);
}*/
