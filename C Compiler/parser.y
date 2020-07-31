%{
#include<iostream>
#include<cstdlib>
#include<cstring>
#include<cmath>
#include<string>
#include<string.h>
#include<stdio.h>
#include<typeinfo>
#include<map>
#include<vector>
#include<stack>
#include<utility>
#include<stdarg.h>
#include<cstdarg>
#include<fstream>
#include "symboltable.cpp"
using namespace std;

int yyparse(void);
int yylex(void);
extern FILE *yyin;

extern int line_counter; //gives us the line counter
extern int error_counter; //keeps track of syntax/sementics error

//FILE* logs; //
FILE* errors;

SymbolTable stable(7);
map<string,string>m; //a map for storing symbols not returned by the symbol table

vector< pair<string,string> >temp_param_list;
vector< pair<string,string> >arg_param_list;
vector<SymbolInfo*>v;
vector< pair<string,string> >decld_var_carrier;   //vector for adding the variables to the assembly CODES
vector< pair<string,string> >var_carrier;
vector< pair<string,string> >decld_f_var;         //vector for the declared variables inside the function to push the variables to the STACK

string type_of_var;
string statement_solver;
bool is_func=false;
string return_type_solver;
int control_arg;
string running_f_name = "";
string scope_holder = "";
int scope_counter = 1;
int scope_counter_2 = 0;

string output_procedure ="\nPRINT_INT PROC\
\n\tPUSH AX \n\tPUSH BX \n\tPUSH CX \n\tPUSH DX\
\n\n\tOR AX,AX \n\tJGE END_IF1 \n\tPUSH AX \n\tMOV DL,'-' \n\tMOV AH,2 \n\tINT 21H \n\tPOP AX \n\tNEG AX\
\n\nEND_IF1: \n\tXOR CX,CX \n\tMOV BX,10D \n\nREPEAT1: \n\tXOR DX,DX \n\tDIV BX \n\tPUSH DX \n\tINC CX \
\n\n\tOR AX,AX \n\tJNE REPEAT1 \n\n\tMOV AH,2 \n\nPRINT_LOOP: \n\tPOP DX \n\tOR DL,30H \n\tINT 21H \n\tLOOP PRINT_LOOP\
\n\tMOV AH,2 \n\tMOV DL,10 \n\tINT 21H \n\n\tMOV DL,13 \n\tINT 21H\
\n\n\tPOP DX \n\tPOP CX \n\tPOP BX \n\tPOP AX \n\tRET\
\nPRINT_INT ENDP\n\n";


int labelCount=0;               //counts the number of label
int tempCount=0;               	//counts the number of temporary varaible

/* A function to generate a new label*/
char *newLabel()
{
	char *lb= new char[4];
	strcpy(lb,"L");
	char b[3];
	sprintf(b,"%d", labelCount);
	labelCount++;
	strcat(lb,b);
	return lb;
}


/* a function to generate a new temporary variable*/
char *newTemp()
{
	char *t= new char[4];
	strcpy(t,"t");
	char b[3];
	sprintf(b,"%d", tempCount);
	tempCount++;
	strcat(t,b);
	return t;
}

/*function that takes variable arguments as member*/
string string_adder(int count, ...)
{
	va_list ap;
	int j;
	const char* tot;
	string result;
	va_start(ap,count);
	for(j=0;j<count;j++)
	{
		tot = va_arg(ap,const char*);
		string temp(tot);
		result = result+temp;
	}

	va_end(ap);
	return result;

}

//detects syntax error
void yyerror(const char *s)
{
	fprintf(errors,"Line no %d : %s\n",line_counter,s);
}

//sets the symbols of the token
void set_token_symbols()
{
	m["comma"] = ",";
	m["semicolon"] = ";";
	m["left_third"] = "[";
	m["right_third"] = "]";
	m["newline"] = "\n";
	m["left_first"] = "(";
	m["right_first"] = ")";
	m["equal"] = "=";
	m["plus"] = "+";
	m["minus"] = "-";
	m["left_curl"] = "{";
	m["right_curl"] = "}";
	m["incop"] = "++";
	m["decop"] = "--";
}

//gets the token symbol
string get_token_symbols(string name)
{
	return m.at(name);
}

vector<string> split_string(const string& str,const string& delimiter)
{
    vector<string> splitted;

    string::size_type pos = 0;
    string::size_type prev = 0;
    while ((pos = str.find(delimiter, prev)) != string::npos)
    {
        splitted.push_back(str.substr(prev, pos - prev));
        prev = pos + 1;
    }

    splitted.push_back(str.substr(prev));

    return splitted;
}

bool is_valid_string(string a, string b)
{
    int a_indx = a.find("MOV");
    int b_indx = b.find("MOV");

    if((a_indx!=string::npos)&&(b_indx!=string::npos))
    {
        if((a.find(",")!=string::npos)&&(b.find(",")!=string::npos))
        {
            return true;
        }
    }

    return false;

}


/*returns an optimized version of the assembly code*/
string optimizer(string code)
{

    string result;
    int i;
    bool is_it_last = false;
    int temp;

    vector<string>vect1;
    vector<string>vect2;

    /*we get the splitted code*/
     vector<string>splitted_code =split_string(code,"\n");

     //removing all the extra newlines from the splitted string
     for(int i=0;i<splitted_code.size();i++)
     {
         if(splitted_code[i]!="")
         {
             vect1.push_back(splitted_code[i]);
         }
     }

     splitted_code.clear();

     for(int i=0;i<vect1.size();i++)
     {
         splitted_code.push_back(vect1[i]);
     }

     vect1.clear();

		 /*this portion checks if a pair of string is valid for comparison and then if we can find our required condition, we skip
		 over one concatenation of the result string, thus giving us an optimized string*/

    for( i=0;i<splitted_code.size();i++)
    {
        temp = i;

        if(i!=splitted_code.size()-1)
        {
            if(is_valid_string(splitted_code[i],splitted_code[i+1]))
            {
                ////cour<<splitted_code[i]<<" "<<splitted_code[i+1]<<endl;
                string temp1 = splitted_code[i].substr(splitted_code[i].find(" ")+1,splitted_code[i].length()-1);
                string temp2 = splitted_code[i+1].substr(splitted_code[i+1].find(" ")+1,splitted_code[i].length()-1); ///
                ////cour<<temp1<<" "<<temp2<<endl;

                vect1 = split_string(temp1,",");
                vect2 = split_string(temp2,",");

                if((vect1[0]==vect2[1])&&(vect1[1]==vect2[0]))
                {
                    i++;
                    ////cour<<i<<endl;
                }

                if((temp+1)==splitted_code.size())
                {
                    is_it_last = true;
                    ////cour<<i<<" "<<temp<<splitted_code.size()<<endl;

                }

            }
        }
        ////cour<<"{"<<splitted_code[temp]<<endl;

        if(!is_it_last)
        {
            result += splitted_code[temp]+"\n";
            ////cour<<"popopopo"<<endl;
        }
        else
            is_it_last = false;


    }

    return result;
}

%}

%union{
SymbolInfo* symbol_pointer;
}


%token FOR IF DO INT FLOAT VOID COMMA SEMICOLON
%token ELSE WHILE DOUBLE CHAR RETURN CONTINUE
%token PRINTLN  ASSIGNOP LPAREN RPAREN
%token LCURL RCURL LTHIRD RTHIRD
%token<symbol_pointer>CONST_INT
%token <symbol_pointer>CONST_FLOAT
%token <symbol_pointer>CONST_CHAR
%token <symbol_pointer>ADDOP
%token <symbol_pointer>MULOP
%token <symbol_pointer>LOGICOP
%token<symbol_pointer>BITOP
%token <symbol_pointer>RELOP
%token<symbol_pointer>INCOP
%token<symbol_pointer>DECOP
%token <symbol_pointer>ID
%token<symbol_pointer>NOT

%type <symbol_pointer> expression logic_expression simple_expression rel_expression  type_specifier term unary_expression variable factor statement expression_statement  compound_statement  declaration_list var_declaration statements func_declaration  func_definition parameter_list unit program argument_list arguments

%nonassoc LOWER_PREC_THAN_ELSE
%nonassoc ELSE

%left RELOP LOGICOP
%left ADDOP
%left MULOP
%error-verbose

%type <symbol_pointer>start
%%

start : program {
				            //fprintf(logs,"Symbol Table: \n\n");
										//stable.printAll(logs);

										/*writing the required codes at the beginning if error count is 0 in the codes*/
										if(error_counter == 0){

											string temp = "";
											string first;
											string second;
											temp = ".MODEL SMALL\n.STACK 100H\n.DATA\n\n";

											/*we now add the variables we declared in the different scopes to the .DATA segment of the code*/
											for(int i = 0;i<decld_var_carrier.size(); i++)
											{
												first  = decld_var_carrier[i].first;
												second = decld_var_carrier[i].second;

												if(second == "")
												{
														temp = temp + first+" DW ?\n";
												}
												else
												{
													temp = temp + first+" DW " + second + " dup(?)\n";
												}

											}

											$1->extra_var.assm_code = temp + ".CODE\n\n" +output_procedure+ $1->extra_var.assm_code;

											ofstream fout;
											fout.open("code.asm");
											fout << $1->extra_var.assm_code;

											/*---call the optimization funcion here---*/
											ofstream fout2;
											fout2.open("optimized-Code.asm");
											fout2<<optimizer($1->extra_var.assm_code);
											////cour<<"optimized code here"<<endl;
											////cour<<optimizer($1->extra_var.assm_code);
										}
								}
    						;

program : program unit {
							//fprintf(logs,"At line no: %d program : program unit\n\n",line_counter);
							string temp = m.at("newline") + $2->extra_var.concatenator;
							$$->extra_var.join_string(temp);
							//fprintf(logs,"%s\n\n\n",$$->extra_var.concatenator.c_str());
							$$->extra_var.assm_code = $1->extra_var.assm_code+$2->extra_var.assm_code;


					   }
	| unit		{
							//fprintf(logs,"At line no: %d program : unit\n\n",line_counter);
							$$->extra_var.concatenator = $1->extra_var.concatenator;
							//fprintf(logs,"%s\n\n\n",$$->extra_var.concatenator.c_str());
							////cour<<$1->extra_var.assm_code<<endl;
							//$$->extra_var.assm_code = $1->extra_var.assm_code;

							//stable.printAll(logs);
					  }
	;

unit : var_declaration {
							//fprintf(logs,"At line no: %d unit : var_declaration\n\n",line_counter);
							$$->extra_var.concatenator = $1->extra_var.concatenator;
							//fprintf(logs,"%s\n\n\n",$$->extra_var.concatenator.c_str());
							/*ICG part*/
							$$->extra_var.assm_code = $1->extra_var.assm_code;
					  }
     | func_declaration
		 {
			//fprintf(logs,"At line no: %d unit : func_declaration\n\n",line_counter);
			$$->extra_var.concatenator = $1->extra_var.concatenator;
			//fprintf(logs,"%s\n\n\n",$$->extra_var.concatenator.c_str());
		 }
     | func_definition
		 {
			//fprintf(logs,"At line no: %d unit : func_definition\n\n",line_counter);
			$$->extra_var.concatenator = $1->extra_var.concatenator;
			//fprintf(logs,"%s\n\n\n",$$->extra_var.concatenator.c_str());
			/*ICG part*/
			$$->extra_var.assm_code = $1->extra_var.assm_code;
		 }
     ;

func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON
				 {
					//fprintf(logs,"At line no: %d func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON\n\n",line_counter);
					SymbolInfo* s=stable.LookUp($2->getName());
					if(s!=0)//found on the symbol table
					{
						string ret_type = s->extra_var.func_ret_type; //return type of already declared function

						//check return type consistencyint
						if(ret_type!=$1->getType())
						{
							error_counter++;
							fprintf(errors,"Error at Line %d :Return Type Mismatch of function declration \n\n",line_counter);
						}

						//checking the size of the parameter_list
						if(s->extra_var.func_param_list.size()!=temp_param_list.size())
						{
							error_counter++;
							fprintf(errors,"Error at Line %d : Unequal number of parameters\n\n",line_counter);
							temp_param_list.clear();

						}else
						{
							//seq of parameters checking
							for(int i=0;i<temp_param_list.size();i++)
							{
								////cour<< temp_param_list[i].first <<endl;
								string temp1 = temp_param_list[i].second;
								string temp2 = s->extra_var.func_param_list[i].second;

								if(temp1!=temp2)
								{
									error_counter++;
									fprintf(errors,"Error at Line %d : Argument Type Mismatch with previous function declaration \n\n",line_counter);
								}
							}
							temp_param_list.clear();
						}

					}
					else
					{
						bool check=false;

						for(int i =0;i<temp_param_list.size();i++)
						{
							if(temp_param_list[i].second=="VOID")
							{
								check = true;
								break;
							}
						}

							SymbolInfo* temp = new SymbolInfo(); //setting up a new object to push in the symbol table
							temp->extra_var.ID_type = "FUNCTION"; //sets the ID type to function
							temp->extra_var.func_ret_type = $1->getType(); //sets the return type of the function
							temp->extra_var.is_function = true;
							temp->extra_var.is_func_declared = true;
							temp->setName($2->getName());
							temp->setType($2->getType());

							if(check) //we set is function to false if there is a void parameter inside our function
							{
								error_counter++;
								fprintf(errors,"Error at Line %d :Parameter cannot be VOID  \n\n",line_counter);
								temp->extra_var.is_function=false;
							}

							for(int i =0;i<temp_param_list.size();i++)
							{
								temp->extra_var.func_param_list.push_back(make_pair(temp_param_list[i].first,temp_param_list[i].second));
							}

							temp_param_list.clear(); //clearing the temporary list so that it can be used again

							stable.Insertmodified(temp); //inserting in the symbol table


					 }

					$$->extra_var.concatenator = $1->extra_var.concatenator+$2->getName()+m["left_first"]+$4->extra_var.concatenator+m["right_first"]+m["semicolon"];
				  //fprintf(logs,"%s\n\n\n",$$->extra_var.concatenator.c_str());

				 }
				 | type_specifier ID LPAREN RPAREN SEMICOLON
				 {
					//fprintf(logs,"At line no: %d func_declaration : type_specifier ID LPAREN RPAREN SEMICOLON\n\n",line_counter);
					SymbolInfo* s=stable.LookUp($2->getName());
					if(s!=0)
					{

						string ret_type = s->extra_var.func_ret_type; //return type of already declared function

						//check return type consistency
						if(ret_type!=$1->getType())
						{
							error_counter++;
							fprintf(errors,"Error at Line %d :Return Type Mismatch of function declration \n\n",line_counter);
						}

						//checking the number of parameters
						if(s->extra_var.func_param_list.size()!=0)
						{
							error_counter++;
							fprintf(errors,"Error at Line %d :Unequal number of parameters  \n\n",line_counter);
							temp_param_list.clear();
						}
					}
					else
					{
						SymbolInfo* temp = new SymbolInfo(); //setting up a new object to push in the symbol table
						temp->extra_var.ID_type = "FUNCTION"; //sets the ID type to function
						temp->extra_var.func_ret_type = $1->getType(); //sets the return type of the function
						temp->extra_var.is_function = true;
						temp->extra_var.is_func_declared = true;
						temp->setName($2->getName());
						temp->setType($2->getType());


						for(int i =0;i<temp_param_list.size();i++)
						{
							temp->extra_var.func_param_list.push_back(make_pair(temp_param_list[i].first,temp_param_list[i].second));
						}

						temp_param_list.clear(); //clearing the temporary list so that it can be used again

						stable.Insertmodified(temp); //inserting in the symbol table

					}

					$$->extra_var.concatenator = $1->extra_var.concatenator+$2->getName()+m["left_first"]+m["right_first"]+m["semicolon"];
				  //fprintf(logs,"%s\n\n\n",$$->extra_var.concatenator.c_str());
				 }
				 ;

func_definition : type_specifier ID LPAREN parameter_list RPAREN
				{
					 scope_counter = scope_counter+1;
					//fprintf(logs,"At line no: %d func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement\n\n",line_counter);

					SymbolInfo* s = stable.LookUp($2->getName());
					bool flag=true;

					if(s==0) //if it does not exist in any scope, we need to insert it as ID
					{
						bool check=false;

						for(int i =0;i<temp_param_list.size();i++)
						{
							if(temp_param_list[i].second=="VOID")
							{
								check=true;
							}

						}

							SymbolInfo* temp = new SymbolInfo(); //setting up a new object to push in the symbol table
							temp->extra_var.ID_type = "FUNCTION"; //sets the ID type to function
							temp->extra_var.func_ret_type = $1->getType(); //sets the return type of the function
							temp->extra_var.is_function = true;
							temp->extra_var.is_func_defined = true;
							temp->setName($2->getName());
							temp->setType($2->getType());

							if(check)
							{
								error_counter++;
								fprintf(errors,"Error at Line %d :Parameter cannot be VOID  \n\n",line_counter);
								temp->extra_var.is_function=false;
							}

							for(int i =0;i<temp_param_list.size();i++)
							{
								temp->extra_var.func_param_list.push_back(make_pair(temp_param_list[i].first,temp_param_list[i].second));
								string t = temp_param_list[i].first+to_string(scope_counter);
								temp->extra_var.modfd_param_list.push_back(t);               //pushing to the modified paramater list of the pointer
							}

							/*if(return_type_solver!=$1->getType())
							{

								error_counter++;
								fprintf(errors,"Error at Line %d : return type error \n\n",line_counter);
								return_type_solver="";
								temp->extra_var.is_function=false;
							}*/

							stable.Insertmodified(temp); //inserting in the symbol table

							//temp_param_list.clear();
					}
					else  //it already exists in global scope(defined or declared)
					{


						//funct is declared
						if(s->extra_var.is_func_defined)
						{
							error_counter++;
							fprintf(errors,"Error at Line %d :Multiple defination of function\n\n",line_counter);
							temp_param_list.clear();
						}
						else if(s->extra_var.is_func_declared)
						{
							//Here we handle three cases
							s->extra_var.is_func_defined = true;
							string ret_type = $1->getType();
							string dec_ret_type = s->extra_var.func_ret_type; //return type of already declared function
							int dec_par_size = s->extra_var.func_param_list.size(); //declared function parameter size
							int def_par_size = temp_param_list.size(); //defined function parameter size

							//return type checking
							if(ret_type!=dec_ret_type)
							{
								error_counter++;
							  fprintf(errors,"Error at Line %d :Return Type Mismatch\n\n",line_counter);
								flag= false;
							}

							//parameter number checking
							if(dec_par_size!=def_par_size)
							{
								error_counter++;
								fprintf(errors,"Error at Line %d :Unequal Number of parameters\n\n",line_counter);
								temp_param_list.clear();
								flag=false;
							}
							else
							{
								//if parameter sizes are equal we check for type sequence of parameters
								for(int i=0;i<temp_param_list.size();i++)
								{
									////cour<< temp_param_list[i].first <<endl;
									string temp1 = temp_param_list[i].second;
									string temp2 = s->extra_var.func_param_list[i].second;
									//problem is here

									if(temp1!=temp2)
									{
										flag=false;
										error_counter++;
										fprintf(errors,"Error at Line %d : Argument Type Mismatch with function declaration \n\n",line_counter);
										break;
									}
								}


								for(int i =0;i<temp_param_list.size();i++)
								{
									string t = temp_param_list[i].first+to_string(scope_counter);
									s->extra_var.modfd_param_list.push_back(t);               //pushing to the modified paramater list of the pointer
								}


							}
							////cour<<return_type_solver<<endl;

						/*	if(return_type_solver!=$1->getType())
							{

								error_counter++;
								fprintf(errors,"Error at Line %d : return type error \n\n",line_counter);
								return_type_solver="";
								flag=false;
							}
							*/

							//flag ? s->extra_var.is_function=true : s->extra_var.is_function=false;
						}

					}

					//$$->extra_var.concatenator = $1->extra_var.concatenator+$2->getName()+m["left_first"]+$4->extra_var.concatenator+m["right_first"]+$6->extra_var.concatenator;
					//fprintf(logs,"%s\n\n",$$->extra_var.concatenator.c_str());


					/*------------------ICG CODES*------------------*/

					running_f_name = $2->getName(); //saving the name to be used during returning
					decld_var_carrier.push_back(make_pair(running_f_name+"_return_val",""));  //saving the variable in the .DATA segment of asm file

				}compound_statement{


					//fprintf(logs,"At line no: %d func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement\n\n",line_counter);
					$$->extra_var.concatenator = $1->extra_var.concatenator+$2->getName()+m["left_first"]+$4->extra_var.concatenator+m["right_first"]+$7->extra_var.concatenator;
					//fprintf(logs,"%s\n\n",$$->extra_var.concatenator.c_str());

					/*------------------ICG CODES*------------------*/

					/*---for the main function---*/
					if($2->getName() == "main")
					{
						$$->extra_var.assm_code += "MAIN PROC\n\tMOV AX,@DATA\n\tMOV DS,AX\n"+$7->extra_var.assm_code+"\nLABEL_RETURN_"+running_f_name+":\n+\n\tMOV AH,4CH\n\tINT 21H\nEND MAIN";
					}
					else /*---we handle for other functions here---*/
					{

						string temp_code = $2->getName()+" PROC\n";

						/*---pushing the register to the STACK---*/
						temp_code += "\tPUSH AX\n\tPUSH BX\n\tPUSH CX\n\tPUSH DX\n\n";

						/*---we lookup the func_id to access the parameter list---*/
						SymbolInfo* s = stable.LookUp($2->getName());
						string hold = "";
						stack<string>s1;
						stack<string>s2;

						/*---we push the parameters of the function to the stack of assm_code---*/
						for(int i=0;i<s->extra_var.func_param_list.size();i++)
						{
						  hold = s->extra_var.func_param_list[i].first+to_string(scope_counter);
							//cour<<hold<<endl;
							//s->extra_var.modfd_param_list.push_back(hold);               //pushing to the modified paramater list of the pointer
							temp_code += "\tPUSH "+hold+"\n";
							s1.push(hold);

						}

						temp_code += "\n";
						scope_holder = "";

						/*---we push the declared variables of the function scope inside the stack of assm_code---*/
						for(int i=0;i<decld_f_var.size();i++)
						{
						  hold = decld_f_var[i].first;
							//cout<<"declared variable inside func  "<<$2->getName()<<" "<<hold<<endl;
							temp_code += "\tPUSH "+hold+"\n";
							s2.push(hold);

						}

						decld_f_var.clear(); //clearing the list so that we would not get any weird variables

						temp_code += "\n";
						temp_code += $7->extra_var.assm_code;
						////cour<<$7->extra_var.assm_code<<endl;

						//changed Here
						temp_code += "LABEL_RETURN_"+running_f_name+":\n";

						/*---we pop the parameters of the function from the stack of assm_code---*/
						while (!s2.empty())
    				{
	        			temp_code += "\tPOP "+s2.top()+"\n";
	        	 		s2.pop();
    				}

						temp_code += "\n";

						/*---we pop the declared variables of the function from the stack of assm_code---*/
						while (!s1.empty())
    				{
	        			temp_code += "\tPOP "+s1.top()+"\n";
	        	 		s1.pop();
    				}

						/*finally we pop the registers from the stack---*/
						temp_code += "\n\tPOP DX\n\tPOP CX\n\tPOP BX\n\tPOP AX\n\tret\n\n";

						temp_code += $2->getName()+" ENDP\n\n";

						/** we set the scope counter to the adjusted value so that next time another f is defined, we get the correct result */
						scope_counter = scope_counter_2;

						$$->extra_var.assm_code += temp_code;

					}


				}

				| type_specifier ID LPAREN RPAREN
			    {
						//fprintf(logs,"At line no: %d func_definition : type_specifier ID LPAREN  RPAREN compound_statement\n\n",line_counter);
						scope_counter++;

						SymbolInfo* s = stable.LookUp($2->getName());

						if(s==0) //if it does not exist in any scope, we need to insert it as ID
						{
							SymbolInfo* temp = new SymbolInfo(); //setting up a new object to push in the symbol table
							temp->extra_var.ID_type = "FUNCTION"; //sets the ID type to function
							temp->extra_var.func_ret_type = $1->getType(); //sets the return type of the function
							temp->extra_var.is_function = true;
							temp->extra_var.is_func_defined = true;
							temp->setName($2->getName());
							temp->setType($2->getType());

							stable.Insertmodified(temp); //inserting in the symbol table

						}
						else  //it already exists in global scope(defined or declared)
						{
							if(s->extra_var.is_func_declared)
							{
								//Here we handle three cases
								string ret_type = $1->getType();
								string dec_ret_type = s->extra_var.func_ret_type; //return type of already declared function

								//return type checking
								if(ret_type!=dec_ret_type)
								{
									error_counter++;
								    fprintf(errors,"Error at Line %d :Return Type Mismatch\n\n",line_counter);
										s->extra_var.is_function = false;
								}

							}
							else if(s->extra_var.is_func_defined) //works
							{
								error_counter++;
								fprintf(errors,"Error at Line %d :Multiple defination of function\n\n",line_counter);
								temp_param_list.clear();
							}
						}
						//$$->extra_var.concatenator = $1->extra_var.concatenator+$2->getName()+m["left_first"]+m["right_first"]+$5->extra_var.concatenator;
						//fprintf(logs,"%s\n\n",$$->extra_var.concatenator.c_str());

						/*------------------ICG CODES*------------------*/

						running_f_name = $2->getName(); //saving the name to be used during returning
						decld_var_carrier.push_back(make_pair(running_f_name+"_return_val",""));  //saving the variable in the .DATA segment of asm file

				}compound_statement{

					//fprintf(logs,"At line no: %d func_definition : type_specifier ID LPAREN  RPAREN compound_statement\n\n",line_counter);
					$$->extra_var.concatenator = $1->extra_var.concatenator+$2->getName()+m["left_first"]+m["right_first"]+$6->extra_var.concatenator;
					//fprintf(logs,"%s\n\n",$$->extra_var.concatenator.c_str());

				/*------------------ICG CODES*------------------*/

					/*for the main function*/
					if($2->getName() == "main")
					{
						$$->extra_var.assm_code += "MAIN PROC\n\tMOV AX,@DATA\n\tMOV DS,AX\n"+$6->extra_var.assm_code+"\nLABEL_RETURN_"+running_f_name+":\n"+"\n\tMOV AH,4CH\n\tINT 21H\nEND MAIN";
					}
					else /*we handle for other functions here*/
					{

						string temp_code = $2->getName()+" PROC\n";

						/*---pushing the register to the STACK---*/
						temp_code += "\tPUSH AX\n\tPUSH BX\n\tPUSH CX\n\tPUSH DX\n\n";

						string hold = "";
						stack<string>s2;

						/*---we push the declared variables of the function scope inside the stack of assm_code---*/
						for(int i=0;i<decld_f_var.size();i++)
						{
							hold = decld_f_var[i].first;
							temp_code += "\tPUSH "+hold+"\n";
							s2.push(hold);

						}

						decld_f_var.clear(); //clearing the list so that we would not get any weird variables

						temp_code += "\n";
						temp_code += $6->extra_var.assm_code;

						//changed Here
						temp_code += "LABEL_RETURN_"+running_f_name+":\n";

						/*---we pop the parameters of the function from the stack of assm_code---*/
						while (!s2.empty())
						{
								temp_code += "\tPOP "+s2.top()+"\n";
								s2.pop();
						}

						temp_code += "\n";

						/*finally we pop the registers from the stack---*/
						temp_code += "\n\tPOP DX\n\tPOP CX\n\tPOP BX\n\tPOP AX\n\tret\n\n";

						temp_code += $2->getName()+" ENDP\n\n";

						$$->extra_var.assm_code += temp_code;

						/** we set the scope counter to the adjusted value so that next time another f is defined, we get the correct result */
						scope_counter = scope_counter_2;

					}

				}
 				;

parameter_list  : parameter_list COMMA type_specifier ID
			  	{
						//fprintf(logs,"At line no: %d parameter_list  : parameter_list COMMA type_specifier ID\n\n",line_counter);
						////cour<<"in par_list:par_lis,ypeid"<<temp_param_list.size()<<endl;
						temp_param_list.push_back(make_pair($4->getName(),$3->getType())); //pushed type to the temp vector
						$$->extra_var.concatenator = $1->extra_var.concatenator+m["comma"]+$3->extra_var.concatenator+$4->getName();
						//fprintf(logs,"%s\n\n",$$->extra_var.concatenator.c_str());
				}
				| parameter_list COMMA type_specifier
				{
						//fprintf(logs,"At line no: %d parameter_list  : parameter_list COMMA type_specifier\n\n",line_counter);
						////cour<<temp_param_list.size()<<endl;
						temp_param_list.push_back(make_pair("",$3->getType())); //pushed type to the temp vector
						$$->extra_var.concatenator = $1->getName()+m["comma"]+$3->extra_var.concatenator;
						//fprintf(logs,"%s\n\n",$$->extra_var.concatenator.c_str());
				}
 				| type_specifier ID
				{
						//fprintf(logs,"At line no: %d parameter_list  : type_specifier ID\n\n",line_counter);
						////cour<<"in type specifier id"<<temp_param_list.size()<<endl;
						temp_param_list.push_back(make_pair($2->getName(),$1->getType())); //pushed type to the temp vector
						$$->extra_var.concatenator = $1->extra_var.concatenator.append($2->getName());
						//fprintf(logs,"%s\n\n",$$->extra_var.concatenator.c_str());

				}
				| type_specifier
				{
						//fprintf(logs,"At line no: %d parameter_list  : type_specifier\n\n",line_counter);
					//	//cour<<temp_param_list.size()<<endl;
						temp_param_list.push_back(make_pair("",$1->getType())); //pushed type to the temp vector
						$$->extra_var.concatenator =$1->extra_var.concatenator;
						//fprintf(logs,"%s\n\n",$$->extra_var.concatenator.c_str());
				}
 				;


compound_statement : LCURL{

							//entering scope when we find a left curl in the Input
							stable.EnterScope();

							/** if the statement enters a new scope, we keep track of the scope by using this variable.
							We will use this variable to set the actual scope counter at the end of func_definition so that the scope is corrected.
							This is required because there can be multiple scope inside the function and whenever we enter in another function, we want that the scope
							counter is always adjusted and gives us the correct value**/

							scope_counter_2 = stable.getCurrScopeID();
							//cour<<"after enteringg scope "<<stable.getCurrScopeID()<<endl;
							//fprintf(errors,"POPEYE");
							scope_holder = to_string(stable.getCurrScopeID());

							if(temp_param_list.size()!=0)
							{
								////cour<<"here"<<endl;
								 	//putting all the arguments of function defination in temp list
								for(int i=0;i<temp_param_list.size();i++)
								{
									string name  = temp_param_list[i].first;
									string type  = temp_param_list[i].second;
									SymbolInfo* s = new SymbolInfo();

									s->setName(name);
									s->setType("ID");
									s->extra_var.var_type = type;
									bool check = stable.Insertmodified(s);
									decld_var_carrier.push_back(make_pair(name+to_string(scope_counter),""));

									if(check==0)
									{
										error_counter++;
										fprintf(errors,"Error at Line %d :Duplicate Parameter Name of function\n\n",line_counter);

									}
								}
							}
							temp_param_list.clear();

						  } statements RCURL{

										  //fprintf(logs,"At line no: %d compound_statement : LCURL statements RCURL\n\n",line_counter);
											$$->extra_var.concatenator = m["left_curl"]+"\n"+$3->extra_var.concatenator+m["right_curl"];
											//fprintf(logs,"%s\n\n",$$->extra_var.concatenator.c_str());
										  //stable.printAll(logs);
											stable.ExitScope();
											//cour<<"after exiting scope "<<stable.getCurrScopeID()<<endl;

											$$->extra_var.assm_code = $3->extra_var.assm_code;

										}
 		    | LCURL
				{
					stable.EnterScope();
					//putting all the arguments of function defination in temp list
					scope_counter_2 = stable.getCurrScopeID();

						for(int i=0;i<temp_param_list.size();i++)
						{
							string name  = temp_param_list[i].first;
							string type  = temp_param_list[i].second;
							SymbolInfo* s = new SymbolInfo();
							s->setName(name);
							s->setType("ID");
							s->extra_var.var_type = type;
							bool check = stable.Insertmodified(s);
							decld_var_carrier.push_back(make_pair(name+to_string(scope_counter),""));
							//fprintf(logs,"printingtocheck");
							//stable.printAll(logs);
							if(check==0)
										{
											error_counter++;
											fprintf(errors,"Error at Line %d :Duplicate Parameter Name of function\n\n",line_counter);
										}
						}
						temp_param_list.clear();

				} RCURL
			 {

				//fprintf(logs,"At line no: %d compound_statement : LCURL  RCURL\n\n",line_counter);
				$$->extra_var.concatenator = m["left_curl"]+"\n"+m["right_curl"];
				//fprintf(logs,"%s\n\n",$$->extra_var.concatenator.c_str());
				//stable.printAll(logs);
				stable.ExitScope();
				//cour<<"after exiting scope "<<stable.getCurrScopeID()<<endl;
			 }
 		    ;

var_declaration : type_specifier declaration_list SEMICOLON
				{
					//fprintf(logs,"At line no: %d var_declaration : type_specifier declaration_list SEMICOLON\n\n",line_counter);
					//$2->extra_var.concatenator.append(get_token_symbols("semicolon"));
					//$1->extra_var.concatenator.append($2->extra_var.concatenator);
					//$$->extra_var.concatenator = $1->extra_var.concatenator;
					$$->extra_var.concatenator = string_adder(3,$1->extra_var.concatenator.c_str(),$2->extra_var.concatenator.c_str(),m["semicolon"].c_str());

					/*for(int i = 0; i<var_carrier.size() ; i++)
					{
						decld_var_carrier.push_back(var_carrier[i]+to_string(stable.getCurrScopeID()));
						//decld_var_carrier.push_back($2->extra_var.var_declared_list[i]+to_string(stable.getCurrScopeID()));
					}*/

					string first;
					string second;

					/*for(int i = 0; i<$2->extra_var.var_declared_list.size() ; i++)
					{
						 first  = $2->extra_var.var_declared_list[i].first;
						 second = $2->extra_var.var_declared_list[i].second;

						 decld_var_carrier.push_back(make_pair(first+to_string(stable.getCurrScopeID()),second));

					}*/


					for(int i = 0; i<var_carrier.size() ; i++)
					{
						 first  = var_carrier[i].first;
						 second = var_carrier[i].second;

						 decld_var_carrier.push_back(make_pair(first+to_string(stable.getCurrScopeID()),second)); //pushing bacl to vector for assm_code declaration

						 if(stable.getCurrScopeID()!=1)
						 {
							 decld_f_var.push_back(make_pair(first+to_string(stable.getCurrScopeID()),second));  //pushing to the vector to be used during function defination procedure
						 }

						 //cour<<"scope id of fun() "<<stable.getCurrScopeID()<<endl;
						 //cout<<"pushing "<<first+to_string(stable.getCurrScopeID())<<" to the lists"<<endl;
					}


					//fprintf(logs,"%s\n\n\n",$$->extra_var.concatenator.c_str());
					var_carrier.clear();
					//$2->extra_var.var_declared_list.clear();
				}
 		 		;

type_specifier	: INT
				{
					////cour<<"In type specifier"<<endl;
					//fprintf(logs,"At line no: %d type_specifier	: INT\n\n",line_counter);
					SymbolInfo* sym_obj = new SymbolInfo("","INT");
					type_of_var = "INT";
					$$ = sym_obj;
					$$->extra_var.concatenator = "int ";
					//fprintf(logs,"%s\n\n",$$->extra_var.concatenator.c_str());

				}
 				| FLOAT
				{
					//fprintf(logs,"At line no: %d type_specifier	: FLOAT\n\n",line_counter);
					SymbolInfo* sym_obj = new SymbolInfo("","FLOAT");
					//sym_obj->extra_var.ID_type = "VARIABLE";
					//sym_obj->extra_var.var_type = "FLOAT";
					type_of_var = "FLOAT";
					$$ = sym_obj;
					$$->extra_var.concatenator = "float ";
					//fprintf(logs,"%s\n\n",$$->extra_var.concatenator.c_str());

				}
 				| VOID
				{
					//fprintf(logs,"At line no: %d type_specifier	: VOID\n\n",line_counter);
					SymbolInfo* sym_obj = new SymbolInfo("","VOID");
					//sym_obj->extra_var.ID_type = "FUNCTION";
					//sym_obj->extra_var.var_type = "VOID";
					type_of_var = "VOID";
					$$ = sym_obj;
					$$->extra_var.concatenator = "void ";
					//fprintf(logs,"%s\n\n",$$->extra_var.concatenator.c_str());
				}
 				;

declaration_list : declaration_list COMMA ID
				 {

					 if(type_of_var!="VOID")
					 {
						 ////cour<<"In dec list,comma id"<<endl;
	 					//fprintf(logs,"At line no : %d declaration_list : declaration_list COMMA ID\n\n",line_counter);
	 					SymbolInfo* test = stable.currentScopeLookUp($3->getName());

	 					if(test!=0)
	 					{
	 						fprintf(errors,"Error at Line %d  : Multiple Declaration of %s\n\n",line_counter,$3->getName().c_str());
	 						error_counter++;
	 					}
	 					else
	 					{
	 						SymbolInfo* obj = new SymbolInfo($3->getName(),$3->getType());
	 						obj->extra_var.ID_type = "VARIABLE";
	 						obj->extra_var.var_type = type_of_var;
	 						stable.Insertmodified(obj);
	 					}

	 					$1->extra_var.concatenator.append(m.at("comma"));
	 					$$->extra_var.concatenator.append($3->getName());
					  //$$->extra_var.var_declared_list.push_back(make_pair($3->getName(),""));   //changed here now
						var_carrier.push_back(make_pair($3->getName(),""));

	 					//fprintf(logs,"%s\n\n",$$->extra_var.concatenator.c_str());
					 }

				 }
 		  	 | declaration_list COMMA ID LTHIRD CONST_INT RTHIRD
		         {

							 if(type_of_var!="VOID")
							 {
								 ////cour<<"inb dec list array"<<endl;
							   //fprintf(logs,"At line no : %d declaration_list : declaration_list COMMA ID LTHIRD CONST_INT RTHIRD\n\n",line_counter);
							   SymbolInfo* test = stable.currentScopeLookUp($3->getName());


							   if(test!=0)
							   {
								 fprintf(errors,"Error at Line %d  : Multiple Declaration of %s\n\n",line_counter,$3->getName().c_str());
								 error_counter++;
							   }
							   else
							   {
								   SymbolInfo* obj = new SymbolInfo($3->getName(),$3->getType());

								   obj->extra_var.ID_type = "ARRAY";
								   obj->extra_var.var_type = type_of_var;
								   obj->extra_var.array_size = $5->getName();
								   stable.Insertmodified(obj);
							   }

							    string temp = $3->getName()+m.at("left_third")+$5->getName()+m.at("right_third");
						  		$1->extra_var.concatenator.append(m.at("comma"));
						  		$$->extra_var.concatenator.append(temp);
									//$$->extra_var.var_declared_list.push_back(make_pair($3->getName(),$5->getName()));  //pushing to the var_dec list to send upwards
									var_carrier.push_back(make_pair($3->getName(),$5->getName()));
									//fprintf(logs,"%s\n\n",$$->extra_var.concatenator.c_str());

							 }

		         }
				| ID
				{
					////cour<<"In declaration_list : ID"<<endl;

					//fprintf(logs,"At line no : %d declaration_list : ID\n\n",line_counter);
					////cour<<"In ID"<<endl;

					if(type_of_var!="VOID")
					{
						//check for ID in symbol table, if does not exist, insert it,else generate error.
						SymbolInfo* temp = stable.currentScopeLookUp($1->getName());
						if(temp!=0)
						{
							error_counter++;
							fprintf(errors,"Error at Line %d  : Multiple declration of %s\n\n",line_counter,$1->getName().c_str());
						}
						else
						{
							SymbolInfo* obj = new SymbolInfo($1->getName(),$1->getType());
							obj->extra_var.ID_type = "VARIABLE";
							obj->extra_var.var_type = type_of_var;
							stable.Insertmodified(obj);
						}
					}
					else
					{
						//generates error if declared variable is void
						error_counter++;
						fprintf(errors,"Error at Line %d  : Variable declared void\n\n",line_counter);
					}

					$$->extra_var.concatenator = $1->getName();                 //assigning the name to the concatenator
					//$$->extra_var.var_declared_list.push_back(make_pair($1->getName(),""));   //inserting in the list to pass the data upwards
					var_carrier.push_back(make_pair($1->getName(),""));
					//fprintf(logs,"%s\n\n",$$->extra_var.concatenator.c_str());


				}
 		  	| ID LTHIRD CONST_INT RTHIRD
		   {
			   ////cour<<"In ID [int]"<<endl;
			   //fprintf(logs,"At line no : %d ID LTHIRD CONST_INT RTHIRD\n\n",line_counter);

				//checking to see if array type is void or not
			   if(type_of_var!="VOID")
			   {
				   //check for array ID in symbol table, if does not exist, insert it,else generate error.
				   SymbolInfo* temp = stable.currentScopeLookUp($1->getName());
				   if(temp!=0)
				   {
					   	fprintf(errors,"Error at Line %d  : Multiple declration of %s\n\n",line_counter,$1->getName().c_str());
							error_counter++;
				   }
				   else
				   {
					   SymbolInfo* obj = new SymbolInfo($1->getName(),$1->getType());
					   obj->extra_var.ID_type = "ARRAY";
					   obj->extra_var.var_type = type_of_var;
					   obj->extra_var.array_size = $3->getName();
					   stable.Insertmodified(obj);
					   ////cour<<$1->getName()<<" "<<obj->extra_var.ID_type<<endl;

				   }
			   }
			   else
			   {
				   fprintf(errors,"Error at Line %d  :  Array %s declared as void\n\n",line_counter,$1->getName().c_str());
				   error_counter++;
			   }

			  string temp = m.at("left_third")+$3->getName()+m.at("right_third");
			  $$->extra_var.concatenator = $1->getName(); //assigning the name to the concatenator
			  $$->extra_var.concatenator.append(temp);
				//$$->extra_var.var_declared_list.push_back(make_pair($1->getName(),$3->getName()));  //pushing to the var_dec list to send upwards
				var_carrier.push_back(make_pair($1->getName(),$3->getName()));
			  //fprintf(logs,"%s\n\n",$$->extra_var.concatenator.c_str());
		   }
 		  ;

statements : statement
		   {
			   //fprintf(logs,"At line no : %d statements : statement\n\n",line_counter);
			   //fprintf(logs,"%d\n\n",sizeof($1));
			   $$->extra_var.concatenator = $1->extra_var.concatenator+"\n";
			   //fprintf(logs,"%s\n\n",$$->extra_var.concatenator.c_str());
				 /*ICG codes*/
				 $$->extra_var.assm_code = $1->extra_var.assm_code;
		   }

	   | statements statement
	   {
		   //fprintf(logs,"At line no : %d statements : statements statement\n\n",line_counter);
		   $$->extra_var.concatenator = $1->extra_var.concatenator+($2->extra_var.concatenator+"\n");
		   statement_solver = $$->extra_var.concatenator;
		   //fprintf(logs,"%s\n\n",$$->extra_var.concatenator.c_str());
		   //fprintf(logs,"%d\n\n",sizeof($2));
			 /*ICG codes*/
			 $$->extra_var.assm_code = $1->extra_var.assm_code+$2->extra_var.assm_code;

	   }
	   ;

statement : var_declaration
		  {
			  //fprintf(logs,"At line no: %d statement : var_declaration\n\n",line_counter);
			  $$->extra_var.concatenator = $1->extra_var.concatenator;
			  //fprintf(logs,"%s\n\n",$$->extra_var.concatenator.c_str());
		  }
	  | expression_statement
	  {
		  //fprintf(logs,"At line no: %d statement : expression_statement\n\n",line_counter);
		  $$->extra_var.concatenator = $1->extra_var.concatenator;
		  //fprintf(logs,"%s\n\n",$$->extra_var.concatenator.c_str());

			$$->extra_var.assm_code = $1->extra_var.assm_code;
	  }
	  | compound_statement
	  {
		  //fprintf(logs,"At line no: %d statement : compound_statement\n\n",line_counter);
		  $$->extra_var.concatenator = $1->extra_var.concatenator;
		  //fprintf(logs,"%s\n\n",$$->extra_var.concatenator.c_str());

			$$->extra_var.assm_code = $1->extra_var.assm_code;

	  }
	  | FOR LPAREN expression_statement expression_statement expression RPAREN statement
	  {
		  //fprintf(logs,"At line no: %d statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement\n\n",line_counter);
		  string temp = $3->extra_var.join_string($4->extra_var.join_string($5->extra_var.concatenator));
		  $$->extra_var.concatenator = "for"+m.at("left_first")+temp+m.at("right_first")+$7->extra_var.concatenator;
		  //fprintf(logs,"%s\n\n",$$->extra_var.concatenator.c_str());

			//var type of expression_statements and expression
			string a = $3->extra_var.var_type;
			string b = $4->extra_var.var_type;
			string c = $5->extra_var.var_type;

			if((a=="VOID")||(b=="VOID")||(c=="VOID"))
			{
				error_counter++;
				fprintf(errors,"Error at Line %d : Expression can not be void\n\n",line_counter);

			}
			else/*ICG codes*/
			{
				string temp_code = $3->extra_var.assm_code;

				char* label1 = newLabel();
				char* label2 = newLabel();

				temp_code += string(label1)+":\n";
				temp_code += $4->extra_var.assm_code;
				temp_code += "\tMOV AX,"+$4->extra_var.carr1+"\n";
				temp_code += "\tCMP AX,0\n";
				temp_code += "\tJE "+string(label2)+"\n";
				temp_code += $7->extra_var.assm_code;
				temp_code += $5->extra_var.assm_code;
				temp_code += "\tJMP "+string(label1)+"\n";
				temp_code += string(label2)+":\n\n";

				$$->extra_var.assm_code = temp_code;
			}

	  }
	  | IF LPAREN expression RPAREN statement %prec LOWER_PREC_THAN_ELSE
	  {
		  //fprintf(logs,"At line no: %d IF LPAREN expression RPAREN statement\n\n",line_counter);
		  string temp = $3->extra_var.join_string(m.at("right_first"));
		  $$->extra_var.concatenator = "if"+m.at("left_first")+temp+$5->extra_var.concatenator;
		  //fprintf(logs,"%s\n\n",$$->extra_var.concatenator.c_str());

			string a = $3->extra_var.var_type;
			if(a=="VOID")
			{
				error_counter++;
				fprintf(errors,"Error at Line %d : Expression can not be void\n\n",line_counter);
			}
			/*ICG code*/
			string temp_code = $3->extra_var.assm_code;
			char* label1 = newLabel();
			temp_code += "\tMOV AX,"+$3->extra_var.carr1+"\n";
			temp_code += "\tCMP AX,0\n";
			temp_code += "\tJE "+string(label1)+"\n";
			temp_code += $5->extra_var.assm_code;
			temp_code += string(label1)+":\n\n";
			$$->extra_var.assm_code = temp_code;

	  }
	  | IF LPAREN expression RPAREN statement ELSE statement
	  {
		  //fprintf(logs,"At line no : %d IF LPAREN expression RPAREN statement ELSE statement\n\n",line_counter);
		  string temp = $3->extra_var.join_string(m.at("right_first"));
		  string temp2 = $5->extra_var.join_string("else"+$7->extra_var.concatenator);
		  $$->extra_var.concatenator = "if"+m.at("left_first")+temp+temp2;
		  //fprintf(logs,"%s\n\n",$$->extra_var.concatenator.c_str());

			string a = $3->extra_var.var_type;
			if(a=="VOID")
			{
				error_counter++;
				fprintf(errors,"Error at Line %d : Expression can not be void\n\n",line_counter);
			}

			/*ICG code*/
			string temp_code = $3->extra_var.assm_code;
			char* label1 = newLabel();
			char* label2 = newLabel();
			temp_code += "\tMOV AX,"+$3->extra_var.carr1+"\n";
			temp_code += "\tCMP AX,0\n";
			temp_code += "\tJE "+string(label1)+"\n";
			temp_code += $5->extra_var.assm_code;
			temp_code += "\tJMP "+string(label2)+"\n";
			temp_code += string(label1)+":\n";
			temp_code += $7->extra_var.assm_code;
			temp_code += string(label2)+":\n\n";

			$$->extra_var.assm_code = temp_code;

	  }
	  | WHILE LPAREN expression RPAREN statement
	  {
		  //fprintf(logs,"At line no: %d WHILE LPAREN expression RPAREN statement\n\n",line_counter);
		  string temp = $3->extra_var.join_string(m.at("right_first")+$5->extra_var.concatenator);
		  $$->extra_var.concatenator = "while"+m.at("left_first")+temp;
		  //fprintf(logs,"%s\n\n",$$->extra_var.concatenator.c_str());

			string a = $3->extra_var.var_type;
			if(a=="VOID")
			{
				error_counter++;
				fprintf(errors,"Error at Line %d : Expression can not be void\n\n",line_counter);
			}
			else
			{

				char* label1 = newLabel();
				char* label2 = newLabel();

				string temp_code = string(label1)+":\n";
				temp_code += $3->extra_var.assm_code;
				temp_code += "\tMOV AX,"+$3->extra_var.carr1+"\n";
				temp_code += "\tCMP AX,0\n";
				temp_code += "\tJE "+string(label2)+"\n";
				temp_code += $5->extra_var.assm_code;
				temp_code += "\tJMP "+string(label1)+"\n";
				temp_code += string(label2)+":\n\n";

				$$->extra_var.assm_code = temp_code;

			}

	  }
	  | PRINTLN LPAREN ID RPAREN SEMICOLON
	  {
		  //fprintf(logs,"At line no: %d statement : PRINTLN LPAREN ID RPAREN SEMICOLON\n\n",line_counter);

		  $$->extra_var.concatenator = "println"+m.at("left_first")+$3->getName()+m.at("right_first")+m.at("semicolon");
		  //fprintf(logs,"%s\n\n",$$->extra_var.concatenator.c_str());

			/*-------ICG code------*/
			/*println(x) <-- x belongs in scope1
			MOV AX,x1
			CALL PRINT_INT*/
			string temp_code = "\n\n\tMOV AX,"+$3->getName()+to_string(stable.IDlookUpWithParam($3->getName()));
			temp_code += "\n\tCALL PRINT_INT\n\n";

			$$->extra_var.assm_code = temp_code;

			////cour<<$$->extra_var.assm_code<<endl;
	  }
	  | RETURN expression SEMICOLON
	  {
		  //fprintf(logs,"At line no: %d statement : RETURN expression SEMICOLON\n\n",line_counter);
		  $$->extra_var.concatenator = "return "+$2->extra_var.join_string(m.at("semicolon"));
		  //fprintf(logs,"%s\n\n",$$->extra_var.concatenator.c_str());

			string a = $2->extra_var.var_type;

			if(a=="VOID")
			{

				error_counter++;
				fprintf(errors,"Error at Line %d : Expression can not be void\n\n",line_counter);

			}
			return_type_solver = a;

			/*-------ICG code------*/
			/*--- we store the return value of the respective procedure in a variable that was declared before.
			Firstly we get the result of the expression and store it in AX. Then we store the result in the
			respective variable to be used later---*/

			string temp_code = $2->extra_var.assm_code;

			/*--- MOV AX,result_of_expression---*/
			temp_code += "\tMOV AX,"+$2->extra_var.carr1+"\n";

			/*--- MOV func_name,AX---*/
			temp_code += "\tMOV "+running_f_name+"_return_val"+",AX\n\n";

			temp_code += "\tJMP LABEL_RETURN_"+running_f_name+"\n";

			$$->extra_var.assm_code = temp_code;

	  }
	  ;

expression_statement 	: SEMICOLON
						{
							//fprintf(logs,"At line no: %d expression_statement : SEMICOLON\n\n",line_counter);
							$$->extra_var.concatenator = m.at("semicolon");
							//fprintf(logs,"%s\n\n",$$->extra_var.concatenator.c_str());
						}
						| expression SEMICOLON
						{
							//fprintf(logs,"At line no: %d expression_statement : expression SEMICOLON\n\n",line_counter);
							$$->extra_var.concatenator = $1->extra_var.join_string(m.at("semicolon"));
							$$->extra_var.var_type = $1->extra_var.var_type;
							//fprintf(logs,"%s\n\n",$$->extra_var.concatenator.c_str());
							/*ICG code here*/
							$$->extra_var.assm_code = $1->extra_var.assm_code;
						}
						;

variable : ID
		{
			////cour<<"In variable: ID"<<endl;
			//fprintf(logs,"At line no: %d variable : ID \n\n",line_counter);
			SymbolInfo* temp =  stable.LookUp($1->getName());
			string type="";
			////cour<<"IN checking = ="<<$1->getName()<<" "<<temp->extra_var.var_type<<endl;
		 	if(temp!=0)
		 	{
				if(temp->extra_var.ID_type=="ARRAY")
				{
					error_counter++;
					fprintf(errors,"Error at Line %d : No index on array\n\n",line_counter,$1->getName().c_str());
					type = temp->extra_var.var_type;
				}
				else if(temp->extra_var.is_function)
				{
					error_counter++;
					fprintf(errors,"Error at Line %d : Improper Function call\n\n",line_counter,$1->getName().c_str());
					type = temp->extra_var.func_ret_type;
				}
				else
				{
					type = temp->extra_var.var_type;
				}

				$$->extra_var.var_type = type;
				$$->extra_var.ID_type = temp->extra_var.ID_type;
				$$->setName(temp->getName());
				$$->setType(temp->getType());
				////cour<<"ekhne"<<endl;
		 	}
			 else //works
		 	{
			 	error_counter++;
			 	fprintf(errors,"Error at Line %d : Undeclared variable : %s\n\n",line_counter,$1->getName().c_str());
		 	}
			//fprintf(logs,"error-verbose at line in undeclraed variable")

			 $$->extra_var.concatenator = $1->getName();
			 //fprintf(logs,"%s\n\n",$$->extra_var.concatenator.c_str());
			 //fprintf(logs,"type is: %s\n\n",$$->extra_var.var_type.c_str());

			 /*ICG codes*/
			 /* here we set the codes for the correct var name with the scope number in assembly */
			 $$->extra_var.carr1 = $1->getName()+to_string(stable.IDlookUpWithParam($1->getName()));
			 $$->extra_var.assm_code = "";
		}
	 | ID LTHIRD expression RTHIRD
	 {

		 //fprintf(logs,"At line no: %d variable : ID LTHIRD expression RTHIRD\n\n",line_counter);
		 //check to see if ID is in scope table or not
		 SymbolInfo* temp = stable.LookUp($1->getName());
		 ////cour<<"IN checking = ="<<$1->getName()<<" "<<temp->extra_var.ID_type<<endl;
		 if(temp!=0)
		 {
			 string id_type = temp->extra_var.ID_type;

			 if(id_type!="ARRAY")
			 {
				 error_counter++;
				 fprintf(errors,"Error at Line %d : Index Not on Array\n\n",line_counter);
			 }
			 else
			 {

					string type = $3->extra_var.var_type; //index expression type
					////cour<<"here"<<endl;
					//int arr_size = stoi(temp->extra_var.array_size); //declared array size

					string arr_type = $1->extra_var.var_type;
					if(type!="INT")
					{
							error_counter++;
							fprintf(errors,"Error at Line %d : Non Integer Array Index\n\n",line_counter);
					}

			 }

			temp->extra_var.is_function ? $$->extra_var.var_type = temp->extra_var.func_ret_type :	$$->extra_var.var_type = temp->extra_var.var_type; //Function retutypeset,else var typeset to result

			$$->extra_var.ID_type = temp->extra_var.ID_type;
			$$->setName(temp->getName());
			$$->setType(temp->getType());
			$$->extra_var.array_index  = temp->extra_var.array_index;
			$$->extra_var.array_size = temp->extra_var.array_size;
		 }
		 else
		 {
			 error_counter++;
			 fprintf(errors,"Error at Line %d : Undeclared variable : %s\n\n",line_counter,$1->getName().c_str());
		 }

		string t = m.at("left_third")+$3->extra_var.join_string(m.at("right_third"));
		$$->extra_var.concatenator = $1->getName()+t;
		//fprintf(logs,"%s\n\n",$$->extra_var.concatenator.c_str());

		/*ICG codes*/
		string tem = $3->extra_var.assm_code;  //eg: MOV t9,10
		tem += "\tMOV BX,"+$3->extra_var.carr1+"\n\tADD BX,BX\n";   //eg: MOV BX,t9   ADD BX,BX
		$$->extra_var.assm_code = tem; //passing the ASM code
		$$->extra_var.carr1 = $1->getName()+to_string(stable.IDlookUpWithParam($1->getName()));

	 }
	 ;

 expression : logic_expression
			{
				//fprintf(logs,"At line no: %d expression : logic_expression\n\n",line_counter);
				$$->extra_var.concatenator = $1->extra_var.concatenator;
				$$->extra_var.var_type = $1->extra_var.var_type;
				//fprintf(logs,"%s\n\n",$$->extra_var.concatenator.c_str());
			}
	   | variable ASSIGNOP logic_expression
	   {

			 ////cour<<"variable is : "<<$1->extra_var.concatenator<<endl;
		   //fprintf(logs,"At line no: %d expression :variable ASSIGNOP logic_expression\n\n",line_counter);

			 SymbolInfo* s = stable.LookUp($1->getName());

			 if(s!=0)
			 {
				 string v_type = s->extra_var.var_type;
				 string log_exp_type = $3->extra_var.var_type;

				 ////cour<<"left "<<v_type<<endl;
				 ////cour<<"right "<<log_exp_type<<endl;

				 if($3->extra_var.var_type=="VOID")
				 {
						 error_counter++;
						 fprintf(errors,"Error at Line %d : Type Mismatch: cannot assign to VOID type\n\n",line_counter);
				 }
				 else
				 {
						 if(v_type!=log_exp_type)
						{
							////cour<<log_exp_type<<endl;
						  error_counter++;
						  fprintf(errors,"Error at Line %d : Type Mismatch\n\n",line_counter);
						}

						if((v_type=="FLOAT")&&(log_exp_type=="INT"))
						{
						  //error_counter++;
						  fprintf(errors,"Warning at Line %d : Integer assigned to Float\n\n",line_counter);
						//check return type consistencyint


						}
						else if((v_type=="INT")&&(log_exp_type=="FLOAT"))
						{
						 	//error_counter++;
						 	fprintf(errors,"Warning at Line %d : Float assigned to Integer\n\n",line_counter);
						}
				 }

			 }

		   $$->extra_var.var_type = $1->extra_var.var_type;

		   ////cour<<"logic exp is : "<<$3->extra_var.concatenator<<endl;
		   $$->extra_var.concatenator = $1->extra_var.concatenator+m["equal"]+$3->extra_var.concatenator;
		   //fprintf(logs,"%s\n\n",$$->extra_var.concatenator.c_str());

			 /*ICG codes*/
			 string temp ="";

			 if($1->extra_var.ID_type == "ARRAY")
			 {

				 temp = $1->extra_var.assm_code;

				 /*create a new temp and save the array index here, later while we have the $3 codes, we can just update the BX before assignment*/
				 char* idx_saver = newTemp();
				 temp+= "\n\tMOV "+string(idx_saver)+",BX\n"; //saving in the temporary variable
				 decld_var_carrier.push_back(make_pair(string(idx_saver),"")); //saving it in the decalred vector
				 ////cour<<"in here 1 "<<$1->extra_var.assm_code<<endl;

				 temp += $3->extra_var.assm_code + "\tMOV AX,"+$3->extra_var.carr1+"\n";
				 ////cour<<"in here 3 "<<$3->extra_var.assm_code<<endl;


				 temp+= "\tMOV BX,"+string(idx_saver)+"\n"; //getting the value again
				 temp += "\tMOV "+$1->extra_var.carr1+"[BX],AX\n\n";
				 $$->extra_var.assm_code = temp;
			 }
			 else
			 {

				 temp = $1->extra_var.assm_code;
				 ////cour<<"in here 1 "<<temp<<endl;
				 temp += $3->extra_var.assm_code + "\tMOV AX,"+$3->extra_var.carr1+"\n";
				 ////cour<<"in here 3 "<<$3->extra_var.assm_code<<endl;

				 temp += "\tMOV "+$1->extra_var.carr1+",AX\n\n";
				 $$->extra_var.assm_code = temp;

			 }

	   }
	   ;

logic_expression : rel_expression
				 {
					 //fprintf(logs,"At line no : %d logic_expression : rel_expression \n\n",line_counter);
					 $$->extra_var.concatenator = $1->extra_var.concatenator;
					 $$->extra_var.var_type = $1->extra_var.var_type;
					 ////cour<<"In log_exp: rel_exp "<<$$->extra_var.concatenator<<" "<<$1->extra_var.concatenator<<endl;
					 //fprintf(logs,"%s\n\n",$$->extra_var.concatenator.c_str());

					 /*ICG code*/
					 $$->extra_var.carr1 = $1->extra_var.carr1;
			 		 $$->extra_var.assm_code = $1->extra_var.assm_code;

				 }
		 | rel_expression LOGICOP rel_expression
		 {
			 //fprintf(logs,"At line no : %d logic_expression : rel_expression LOGICOP rel_expression \n\n",line_counter);
			 string a_type  = $1->extra_var.var_type;
			 string b_type  =  $2->extra_var.var_type;
			 if((a_type=="VOID") || (b_type =="VOID"))
			 {
				 error_counter++;
				 fprintf(errors,"Error at Line %d  : Type Mismatch: cannot operate on VOID type\n\n",line_counter);
			 }
			 string res_type = "INT";
			 $$->extra_var.var_type = res_type;
			 string temp = $1->extra_var.join_string($2->getName()+$3->extra_var.concatenator);
			 $$->extra_var.concatenator = temp;
			 //fprintf(logs,"%s\n\n",$$->extra_var.concatenator.c_str());
			 //check for VOID

			 /*ICG code*/
			 string temp_code = $1->extra_var.assm_code + $3->extra_var.assm_code;
			 char* label1 = newLabel();
			 char* label2 = newLabel();
			 char* label3 = newLabel();
			 char* temp_var = newTemp();

			 if($2->getName() == "&&")
			 {
				 temp_code += "\n\tMOV AX,"+$1->extra_var.carr1+"\n";
				 temp_code += "\tCMP AX,1";
				 temp_code += "\n\tJNE "+string(label2)+"\n";
				 temp_code += "\tMOV AX,"+$3->extra_var.carr1+"\n";
				 temp_code += "\tCMP AX,1";
				 temp_code += "\n\tJNE "+string(label2)+"\n";
				 temp_code += string(label1)+":\n\tMOV "+string(temp_var)+",1\n"+"\tJMP "+string(label3)+"\n";
				 temp_code += string(label2)+":\n\tMOV "+string(temp_var)+",0\n";
				 temp_code += string(label3)+":\n\n";

				 $$->extra_var.assm_code = temp_code;
				 $$->extra_var.carr1 = string(temp_var);
				 decld_var_carrier.push_back(make_pair(string(temp_var),""));
			 }
			 else if($2->getName() == "||")
			 {
				 temp_code += "\n\tMOV AX,"+$1->extra_var.carr1+"\n";
				 temp_code += "\tCMP AX,1";
				 temp_code += "\n\tJE "+string(label2)+"\n";
				 temp_code += "\tMOV AX,"+$3->extra_var.carr1+"\n";
				 temp_code += "\tCMP AX,1";
				 temp_code += "\n\tJE "+string(label2)+"\n";
				 temp_code += string(label1)+":\n\tMOV "+string(temp_var)+",0\n"+"\tJMP "+string(label3)+"\n";
				 temp_code += string(label2)+":\n\tMOV "+string(temp_var)+",1\n";
				 temp_code += string(label3)+":\n\n";

				 $$->extra_var.assm_code = temp_code;
				 $$->extra_var.carr1 = string(temp_var);
				 decld_var_carrier.push_back(make_pair(string(temp_var),""));

			 }

		 }
		 ;

rel_expression	: simple_expression
				{
					 //fprintf(logs,"At line no : %d rel_expression : simple_expression \n\n",line_counter);
					 $$->extra_var.concatenator = $1->extra_var.concatenator;
					 $$->extra_var.var_type = $1->extra_var.var_type;
					 ////cour<<"In re_exp:simple_exp: "<<$$->extra_var.concatenator<<" "<<$$->extra_var.concatenator<<endl;
					 //fprintf(logs,"%s\n\n",$$->extra_var.concatenator.c_str());

					 /*ICG code*/
					 $$->extra_var.carr1 = $1->extra_var.carr1;
			 		 $$->extra_var.assm_code = $1->extra_var.assm_code;
				}
		| simple_expression RELOP simple_expression
		{
			//fprintf(logs,"At line no : %d rel_expression : simple_expression RELOP simple_expression \n\n",line_counter);

			string a_type  = $1->extra_var.var_type;
			string b_type  =  $2->extra_var.var_type;
			if((a_type=="VOID") || (b_type =="VOID"))
			{
				error_counter++;
				fprintf(errors,"Error at Line %d  : Type Mismatch: cannot operate on VOID type\n\n",line_counter);
			}

			string res_type = "INT";
			$$->extra_var.var_type = res_type;
			string temp = $1->extra_var.join_string($2->getName()+$3->extra_var.concatenator);
			$$->extra_var.concatenator = temp;
			//fprintf(logs,"%s\n\n",$$->extra_var.concatenator.c_str());
			//check for VOID

			/*ICG code*/
			string temp_code = $1->extra_var.assm_code + $3->extra_var.assm_code;
			temp_code += "\tMOV AX,"+$1->extra_var.carr1+"\n"+"\tCMP AX,"+$3->extra_var.carr1+"\n";
			char *temp_var=newTemp();
			char *label1=newLabel();
			char *label2=newLabel();
			if($2->getName()=="<"){
				temp_code += "\tJL "+string(label1)+"\n";
			}
			else if($2->getName()=="<="){
				temp_code += "\tJLE "+string(label1)+"\n";
			}
			else if($2->getName()==">"){
				temp_code += "\tJG "+string(label1)+"\n";
			}
			else if($2->getName()==">="){
				temp_code += "\tJGE "+string(label1)+"\n";
			}
			else if($2->getName()=="=="){
				temp_code += "\tJE "+string(label1)+"\n";
			}
			else{
				temp_code += "\tJNE "+string(label1)+"\n";
			}

			temp_code += "\tMOV "+string(temp_var)+",0\n"+"\tJMP "+string(label2)+"\n";
			temp_code += string(label1)+":\n\tMOV "+string(temp_var)+",1\n";
			temp_code += string(label2)+":\n\n";
			$$->extra_var.assm_code = temp_code;
			$$->extra_var.carr1 = string(temp_var);
			decld_var_carrier.push_back(make_pair(string(temp_var),""));

		}
		;


simple_expression : term
				  {
					  //fprintf(logs,"At line no : %d simple_expression : term \n\n",line_counter);
					  $$->extra_var.concatenator = $1->extra_var.concatenator;
					  $$->extra_var.var_type = $1->extra_var.var_type;
					  //fprintf(logs,"%s\n\n",$$->extra_var.concatenator.c_str());

						/*ICG code*/
		 			 $$->extra_var.carr1 = $1->extra_var.carr1;
		 	 		 $$->extra_var.assm_code = $1->extra_var.assm_code;

				  }
		  | simple_expression ADDOP term
		  {
			  //fprintf(logs,"At line no : %d simple_expression : simple_expression ADDOP term \n\n",line_counter);

			  ////cour<<"$1 has = "<<$1->extra_var.concatenator<<endl;
			  string a_type = $1->extra_var.var_type;
			  string b_type = $3->extra_var.var_type;
			  string res_type  = "";

			  //type checking for operands to be added and type conversion as such
			  if((a_type=="VOID")||(b_type=="VOID"))
			  {
				  error_counter++;
			    fprintf(errors,"Error at Line %d  : Add operation with void\n\n",line_counter);
				  res_type = "INT";

			  }else if((a_type=="FLOAT")||(b_type=="FLOAT"))
			  {
						if(((a_type=="FLOAT")&&(b_type=="INT"))||((a_type=="INT")&&(b_type=="FLOAT")))
	 					 fprintf(errors,"Warning at Line %d  : Integer converted to float during Addition.\n\n",line_counter);
	 				 res_type = "FLOAT";

			  }else if((a_type=="INT")&&(b_type=="INT"))
			  {
				  res_type = "INT";
			  }

			  SymbolInfo* s = new SymbolInfo("",res_type);
			  $$ = s;
			  $$->extra_var.var_type = res_type;
			  $$->extra_var.concatenator = $1->extra_var.join_string($2->getName().append($3->extra_var.concatenator));
			  //fprintf(logs,"%s\n\n",$$->extra_var.concatenator.c_str());

				/*ICG code*/
				string temp_codes = "\n"+$1->extra_var.assm_code+$3->extra_var.assm_code;
				temp_codes += "\n\tMOV AX,"+$1->extra_var.carr1+"\n";

				//generate a temporary var for result
				char* temp_var = newTemp();

				if($2->getName() == "+")
				{
					temp_codes += "\tADD AX,"+$3->extra_var.carr1+"\n"+"\tMOV "+string(temp_var)+",AX\n\n";

				}
				else if($2->getName() == "-")
				{
					temp_codes += "\tSUB AX,"+$3->extra_var.carr1+"\n"+"\tMOV "+string(temp_var)+",AX\n\n";
				}

				$$->extra_var.assm_code = temp_codes;
				$$->extra_var.carr1 = string(temp_var);  //propagating the result through the temporary var
				decld_var_carrier.push_back(make_pair(string(temp_var),"")); //pushing to the declared variable lists

		  }
		  ;

term :	unary_expression
	 {
		//fprintf(logs,"At line no: %d term : unary_expression \n\n",line_counter);
		$$->extra_var.concatenator = $1->extra_var.concatenator;
		$$->extra_var.var_type = $1->extra_var.var_type;
		//fprintf(logs,"%s\n\n",$$->extra_var.concatenator.c_str());

		/*ICG code*/
		$$->extra_var.carr1 = $1->extra_var.carr1;
		$$->extra_var.assm_code = $1->extra_var.assm_code;

	 }
     |  term MULOP unary_expression
	 {
		// //cour<<"IN mulop"<<endl;
		 //fprintf(logs,"At line no: %d term : term MULOP unary_expression \n\n",line_counter);

		 string term_type = $1->extra_var.var_type;
		 string unary_type = $3->extra_var.var_type;
		 string mult_operator = $2->getName();
		 string res_type = "";

		 map<string,int>command_map;
		 command_map["*"] = 1;
		 command_map["/"] = 2;
		 command_map["%"] = 3;

		 /*ICG codes*/
		 char* temp_var = newTemp();
		 string res = string(temp_var);  //contains the result
		 string temp_code = $1->extra_var.assm_code+$3->extra_var.assm_code;


		 switch(command_map[mult_operator])
		 {
			 case 1:
			 		{
						if((term_type=="VOID")||(unary_type=="VOID"))
						{
							error_counter++;
							fprintf(errors,"Error at Line %d : Multiplication operation with void\n\n",line_counter);
							res_type = "INT";
						}
						else if((term_type=="FLOAT")||(unary_type=="FLOAT"))
						{

							if(((term_type=="FLOAT")&&(unary_type=="INT"))||((term_type=="INT")&&(unary_type=="FLOAT")))
								fprintf(errors,"Warning at Line %d : Integer converted to float during Multiplication.\n\n",line_counter);
							res_type = "FLOAT";
						}
						else if((term_type=="INT")&&(term_type=="INT"))
						{
							res_type = "INT";
						}

						SymbolInfo* s = new SymbolInfo("",res_type);
						$$ = s;
						$$->extra_var.var_type = res_type;
						$$->extra_var.concatenator = $1->extra_var.join_string($2->getName().append($3->extra_var.concatenator));
						//fprintf(logs,"%s\n\n",$$->extra_var.concatenator.c_str());

						/*ICG code */

						temp_code += "\n\tMOV AX,"+$1->extra_var.carr1+"\n"+"\tMOV BX,"+$3->extra_var.carr1+"\n"+"\tMUL BX\n"+"\tMOV "+res+",AX\n\n";
						$$->extra_var.assm_code = temp_code;
						$$->extra_var.carr1 = res;
						decld_var_carrier.push_back(make_pair(res,"")); //pushing to the declared variable list

					}
			 break;
			 case 2:{
						if((term_type=="VOID")||(unary_type=="VOID"))
						{
							error_counter++;
							fprintf(errors,"Error at Line %d : Division operation with void\n\n",line_counter);
							res_type = "INT";
						}
						else if((term_type=="FLOAT")||(unary_type=="FLOAT"))
						{

							if(((term_type=="FLOAT")&&(unary_type=="INT"))||((term_type=="INT")&&(unary_type=="FLOAT")))
								fprintf(errors,"Warning at Line %d : Integer converted to float during Division.\n\n",line_counter);
							res_type = "FLOAT";
						}
						else if((term_type=="INT")&&(term_type=="INT"))
						{
							res_type = "INT";
						}

						SymbolInfo* s = new SymbolInfo("",res_type);
						$$ = s;
						$$->extra_var.var_type = res_type;
						$$->extra_var.concatenator = $1->extra_var.join_string($2->getName().append($3->extra_var.concatenator));
						//fprintf(logs,"%s\n\n",$$->extra_var.concatenator.c_str());

						/*ICG code */
						temp_code += "\n\tXOR DX,DX\n";
						temp_code += "\tMOV AX,"+$1->extra_var.carr1+"\n"+"\tMOV BX,"+$3->extra_var.carr1+"\n"+"\tDIV BX\n"+"\tMOV "+res+",AX\n\n";
						$$->extra_var.assm_code = temp_code;
						$$->extra_var.carr1 = res;
						decld_var_carrier.push_back(make_pair(res,"")); //pushing to the declared variable list

					}
			 break;
			 case 3:{
						if((term_type=="VOID")||(unary_type=="VOID"))
						{
							error_counter++;
							fprintf(errors,"Error at Line %d : Integer operand not on modulus operator\n\n",line_counter);
							res_type = "INT";
						}
						else if((term_type!="INT")||(unary_type!="INT"))
						{
							error_counter++;
							fprintf(errors,"Error at Line %d : Integer operand not on modulus operator\n\n",line_counter);
							res_type = "INT";
						}
						else if((term_type=="INT")&&(term_type=="INT"))
						{
							res_type = "INT";
						}

						SymbolInfo* s = new SymbolInfo("",res_type);
						$$ = s;
						$$->extra_var.var_type = res_type;
						$$->extra_var.concatenator = $1->extra_var.join_string($2->getName().append($3->extra_var.concatenator));
						//fprintf(logs,"%s\n\n",$$->extra_var.concatenator.c_str());

						/*ICG code */
						temp_code += "\n\tXOR DX,DX\n";
						temp_code += "\tMOV AX,"+$1->extra_var.carr1+"\n"+"\tMOV BX,"+$3->extra_var.carr1+"\n"+"\tDIV BX\n"+"\tMOV "+res+",DX\n\n";
						$$->extra_var.assm_code = temp_code;
						$$->extra_var.carr1 = res;
						decld_var_carrier.push_back(make_pair(res,"")); //pushing to the declared variable list

					}
			 break;
		 }
	 }
     ;

unary_expression : ADDOP unary_expression
				 {
					 //fprintf(logs,"At line no: %d unary_expression : ADDOP unary_expression\n\n",line_counter);
					 $$->extra_var.concatenator = $1->getName().append($2->extra_var.concatenator);
					 $$->extra_var.var_type = $2->extra_var.var_type;
					 //fprintf(logs,"%s\n\n",$$->extra_var.concatenator.c_str());
					 //check for void
					 if($2->extra_var.concatenator=="VOID")
					 {
						 fprintf(errors,"Error at Line %d : Unary expression cannot be void\n\n",line_counter);
						 error_counter++;
					 }
					 else
					 {
						 string temp_code = $2->extra_var.assm_code;

						 if($1->getName() == "-")
						 {
							 temp_code += "\tMOV AX,"+$2->extra_var.carr1+"\n"+"\tNEG AX\n"+"\tMOV "+$2->extra_var.carr1+",AX\n\n";
							 $$->extra_var.assm_code = temp_code;
							 $$->extra_var.carr1 = $2->extra_var.carr1;

						 }

					 }
				 }
					 | NOT unary_expression
					 {
					  //fprintf(logs,"At line no: %d unary_expression : NOT unary_expression\n\n",line_counter);
					  $$->extra_var.concatenator = $1->getName().append($2->extra_var.concatenator);
						$$->extra_var.var_type = "INT";
					  //fprintf(logs,"%s\n\n",$$->extra_var.concatenator.c_str());
						//check for void
						if($2->extra_var.concatenator=="VOID")
						{
							fprintf(errors,"Error at Line %d : Unary expression cannot be void\n\n",line_counter);
							error_counter++;
						}
						else
						{
							char *temp_var=newTemp();
							string temp_code = $2->extra_var.assm_code;
							temp_code += "\tMOV AX,"+$2->extra_var.carr1+"\n"+"\tNOT AX\n"+"\tMOV "+string(temp_var)+",AX\n";

							$$->extra_var.assm_code = temp_code;
							$$->extra_var.carr1 = string(temp_var);
							decld_var_carrier.push_back(make_pair(string(temp_var),""));
						}
		 }
		 | factor
		 {
			 //fprintf(logs,"At line no: %d unary_expression : factor\n\n",line_counter);
			 $$->extra_var.concatenator = $1->extra_var.concatenator;
			 $$->extra_var.var_type = $1->extra_var.var_type;
			 //fprintf(logs,"%s\n\n",$$->extra_var.var_type.c_str());
			 //fprintf(logs,"%s\n\n",$$->extra_var.concatenator.c_str());

			 /*ICG code*/
			 $$->extra_var.carr1 = $1->extra_var.carr1;
	 		 $$->extra_var.assm_code = $1->extra_var.assm_code;

		 }
		 ;

factor	: variable
		{
			 //fprintf(logs,"At line no: %d factor : variable\n\n",line_counter);
			 $$->extra_var.concatenator = $1->extra_var.concatenator;
			 $$->extra_var.var_type = $1->extra_var.var_type;
			 //fprintf(logs,"%s\n\n",$$->extra_var.concatenator.c_str());

			 /*ICG codes here*/
			 string temp_code = $1->extra_var.assm_code;

			 if($1->extra_var.ID_type == "ARRAY")
			 {
				 char* temp_var = newTemp();
				 temp_code += "\tMOV AX,"+$1->extra_var.carr1+"[BX]\n"+"\tMOV "+string(temp_var)+",AX\n";
				 decld_var_carrier.push_back(make_pair(string(temp_var),""));
				 $$->extra_var.carr1 = string(temp_var);
				 $$->extra_var.assm_code = temp_code;
			 }
			 else
			 {
				 $$->extra_var.carr1 = $1->extra_var.carr1;
				 $$->extra_var.assm_code = temp_code;
			 }

		}
	| ID LPAREN argument_list RPAREN
	{

		//fprintf(logs,"At line no: %d factor : ID LPAREN argument_list RPAREN\n\n",line_counter);

		$$->extra_var.concatenator = $1->getName()+m["left_first"]+$3->extra_var.concatenator+m["right_first"];
		//fprintf(logs,"%s\n\n",$$->extra_var.concatenator.c_str());

		SymbolInfo* s = stable.LookUp($1->getName());

		if(s==0)
		{

			error_counter++;
			fprintf(errors,"Error at Line %d : Undefined or Undeclared function\n\n",line_counter);
			$3->extra_var.func_param_list.clear();

		}
		else
		{

			if(s->extra_var.ID_type=="FUNCTION")
			{
				if(s->extra_var.is_function)
				{
					//check the num of arguments matches or not
					int given_arg_list = $3->extra_var.func_param_list.size();
					int defined_arg_list = s->extra_var.func_param_list.size();

					if(given_arg_list!=defined_arg_list)
					{
						error_counter++;
						fprintf(errors,"Error at Line %d : Unequal Number of function arguments\n\n",line_counter);
						$3->extra_var.func_param_list.clear();
					}
					else
					{
						//Finally check for argument sequence of defined and called function
						for(int i=0;i<defined_arg_list;i++)
						{
							string temp1 = $3->extra_var.func_param_list[i].second;
							string temp2 = s->extra_var.func_param_list[i].second;

								if(temp1!=temp2)
								{
									error_counter++;
									fprintf(errors,"Error at Line %d : Argument Type Mismatch with function defination \n\n",line_counter);
									break;
								}

						}

						$3->extra_var.func_param_list.clear();
					}

				 $$->extra_var.var_type = s->extra_var.func_ret_type; //sets the return type of the function as var type
				 $$->extra_var.ID_type = s->extra_var.ID_type;
				}
				else
				{
					error_counter++;
					fprintf(errors,"Error at Line %d :function not properly defined or declared \n\n",line_counter);
					$$->extra_var.var_type = s->extra_var.func_ret_type; //sets the return type of the function as var type
				 $$->extra_var.ID_type = s->extra_var.ID_type;
				}


			}
			else
			{
				error_counter++;
				fprintf(errors,"Error at Line %d : Function call on Non function ID\n\n",line_counter);
				$$->extra_var.var_type = "INT";
				arg_param_list.clear();
			}

			/*-------------ICG code------------*/
			string temp_code = $3->extra_var.assm_code;
			//cour<<"in f_call: "<<endl;
			//cour<<$3->extra_var.assm_code<<endl;
			////cour<<temp_code<<endl;


			/*---the modified param list is assigned to the respective parameter variables of the assembly code, we also use the result of expressions
			we passed from argument list grammers---*/

			for(int i=0; i<s->extra_var.modfd_param_list.size();i++)
			{
				//cour<<"in here"<<endl;
				temp_code += "\tMOV AX,"+$3->extra_var.var_declared_list[i].first+"\n";
				temp_code += "\tMOV "+s->extra_var.modfd_param_list[i]+",AX\n";

			}

			/*---we call the function now---*/
			temp_code += "\tCALL "+$1->getName()+"\n";
			temp_code += "\tMOV AX,"+$1->getName()+"_return_val"+"\n";

			/*---creating a new temp var to store the result---*/
			char* temp_var = newTemp();
			string result = string(temp_var);

			temp_code += "\tMOV "+result+",AX\n";

			$$->extra_var.assm_code = temp_code;
			decld_var_carrier.push_back(make_pair(result,""));
			$$->extra_var.carr1 = result;
		}

	}
	| LPAREN expression RPAREN
	{
		//fprintf(logs,"At line no: %d factor : LPAREN expression RPAREN\n\n",line_counter);
		SymbolInfo* s = new SymbolInfo();

		string temp = m.at("left_first")+$2->extra_var.join_string(m.at("right_first"));
		s->extra_var.concatenator = temp;
		s->extra_var.var_type = $2->extra_var.var_type;
		$$=s;
		//fprintf(logs,"%s\n\n",$$->extra_var.concatenator.c_str());

		/*ICG code*/
		$$->extra_var.assm_code = $2->extra_var.assm_code;
		$$->extra_var.carr1 = $2->extra_var.carr1;

	}
	| CONST_INT
	{
		//fprintf(logs,"At line no: %d factor : CONST_INT\n\n",line_counter);
		$1->extra_var.var_type = "INT";
		$1->extra_var.ID_type = "CONST_INT";
		$$->extra_var.concatenator = $1->getName();
		$$->extra_var.array_index = $1->getName();
		$$->extra_var.ID_type = $1->extra_var.ID_type;
		$$->extra_var.var_type = $1->extra_var.var_type;
		//fprintf(logs,"%s\n\n",$$->extra_var.concatenator.c_str());

		/*----ICG code----*/
		//char *temp_var = newTemp(); //generating a new temporary variable
		//string temp_str = "\tMOV "+string(temp_var)+","+$1->getName()+"\n";
		//$$->extra_var.carr1 = string(temp_var);
		//$$->extra_var.assm_code = temp_str;
		//decld_var_carrier.push_back(make_pair(string(temp_var),""));
		$$->extra_var.carr1 = $1->getName();
	}
	| CONST_FLOAT
	{
		//fprintf(logs,"At line no: %d factor : CONST_FLOAT\n\n",line_counter);
		$1->extra_var.var_type = "FLOAT";
		$1->extra_var.ID_type = "CONST_FLOAT";
		//fprintf(logs,"At line no: %d factor : CONST_FLOAT\n\n",line_counter);
		$$->extra_var.concatenator = $1->getName();
		$$->extra_var.array_index = $1->getName();
		$$->extra_var.ID_type = $1->extra_var.ID_type;
		$$->extra_var.var_type = $1->extra_var.var_type;
		//fprintf(logs,"%s\n\n",$$->extra_var.concatenator.c_str());

		/*ICG code*/
		/*char *temp_var = newTemp(); //generating a new temporary variable
		string temp_str = "\tMOV "+string(temp_var)+","+$1->getName()+"\n";
		$$->extra_var.carr1 = string(temp_var);
		$$->extra_var.assm_code = temp_str;
		decld_var_carrier.push_back(make_pair(string(temp_var),""));*/
		$$->extra_var.carr1 = $1->getName();

	}
	| variable INCOP
	{
		//fprintf(logs,"At line no: %d factor : variable INCOP\n\n",line_counter);
		$$->extra_var.var_type = $1->extra_var.var_type;
		$$->extra_var.concatenator = $1->getName()+$2->getName();
		//fprintf(logs,"%s\n\n",$$->extra_var.concatenator.c_str());

		/*ICG codes*/
		char* temp_var = newTemp();
		string temp_code = $1->extra_var.assm_code;

		if($1->extra_var.ID_type=="ARRAY")
		{
			temp_code += "\tMOV AX,"+$1->extra_var.carr1+"[BX]\n"+"\tMOV "+string(temp_var)+",AX\n"+"\tINC AX\n"+"\tMOV "+$1->extra_var.carr1+"[BX],AX\n\n";
		}
		else
		{
			temp_code += "\tMOV AX,"+$1->extra_var.carr1+"\n"+"\tMOV "+string(temp_var)+",AX\n"+"\tINC AX\n"+"\tMOV "+$1->extra_var.carr1+",AX\n\n";

		}

		$$->extra_var.assm_code = temp_code;
		$$->extra_var.carr1 = string(temp_var);
		decld_var_carrier.push_back(make_pair(string(temp_var),""));


	}
	| variable DECOP
	{
		//fprintf(logs,"At line no: %d factor : variable DECOP\n\n",line_counter);
		$$->extra_var.var_type = $1->extra_var.var_type;
		$$->extra_var.concatenator = $1->getName()+$2->getName();
		//fprintf(logs,"%s\n\n",$$->extra_var.concatenator.c_str());

		/*ICG codes*/
		char* temp_var = newTemp();
		string temp_code = $1->extra_var.assm_code;

		if($1->extra_var.ID_type=="ARRAY")
		{
			temp_code += "\tMOV AX,"+$1->extra_var.carr1+"[BX]\n"+"\tMOV "+string(temp_var)+",AX\n"+"\tDEC AX\n"+"\tMOV "+$1->extra_var.carr1+"[BX],AX\n\n";
		}
		else
		{
			temp_code += "\tMOV AX,"+$1->extra_var.carr1+"\n"+"\tMOV "+string(temp_var)+",AX\n"+"\tDEC AX\n"+"\tMOV "+$1->extra_var.carr1+",AX\n\n";

		}
		$$->extra_var.assm_code = temp_code;
		$$->extra_var.carr1 = string(temp_var);
		decld_var_carrier.push_back(make_pair(string(temp_var),""));

	}
	;

argument_list : arguments
							{
									//fprintf(logs,"At line no: %d argument_list : arguments\n\n",line_counter);

								//so we can get variable name and type Here
									SymbolInfo* s=new SymbolInfo();
									s->extra_var.concatenator=$1->extra_var.concatenator;
									for(int i=0;i<$1->extra_var.func_param_list.size();i++)
									{
										s->extra_var.func_param_list.push_back(make_pair($1->extra_var.func_param_list[i].first,$1->extra_var.func_param_list[i].second));   //pushing the parameters
										s->extra_var.var_declared_list.push_back(make_pair($1->extra_var.var_declared_list[i].first,""));     //pushing the carriers of expressions of argument_list
									}

									s->extra_var.assm_code = $1->extra_var.assm_code;
									$$=s;

									//fprintf(logs,"%s\n\n",$$->extra_var.concatenator.c_str());
							}
							|
							{
								SymbolInfo* s = new SymbolInfo("","");
								$$=s;
							}
			  			;

arguments : arguments COMMA logic_expression
			    {
						//fprintf(logs,"At line no: %d aarguments : arguments COMMA logic_expression\n\n",line_counter);
						$$->extra_var.var_type = $1->extra_var.concatenator.append(m["comma"]+$3->extra_var.concatenator);

						string name = $3->getName();
						string variable_type = $3->extra_var.var_type;

						if($3->extra_var.var_type == "VOID")
						{
							error_counter++;
							//fprintf(logs,"At line no: %d Void passed as parameter\n\n",line_counter);
						}
						else
						{
							$$->extra_var.func_param_list.push_back(make_pair(name,variable_type));
						}

						//fprintf(logs,"%s\n\n",$$->extra_var.concatenator.c_str());

						/*-------------ICG code------------*/

						/* here we insert the assembly result of each of the expression inside the
						variable declaration list of our symbol info pointer which is currently unused*/
						$$->extra_var.var_declared_list.push_back(make_pair($3->extra_var.carr1,""));

						/*---pasing the assm_code---*/
						$$->extra_var.assm_code = $1->extra_var.assm_code+$3->extra_var.assm_code;

					}
	      | logic_expression
				{

					//fprintf(logs,"At line no: %d arguments : logic_expression\n\n",line_counter);
					//we can get VARIABLE and CONSTANT type clearly
					//cases for array passing and function passing
					////cour<<"here"<<endl;

					string name = $1->getName();
					string variable_type = $1->extra_var.var_type;
					//	//cour<<"type "<<variable_type<<endl;

					if($1->extra_var.var_type == "VOID")
					{
						error_counter++;
						//fprintf(logs,"At line no: %d Void passed as parameter\n\n",line_counter);
					}
					else
					{
						$$->extra_var.func_param_list.push_back(make_pair(name,variable_type));

					}

					$$->extra_var.concatenator = $1->extra_var.concatenator;
					//fprintf(logs,"%s\n\n",$$->extra_var.concatenator.c_str());

					/*-------------ICG code------------*/

					/* here we insert the assembly result of each of the expression inside the
					variable declaration list of our symbol info pointer which is currently unused*/
					$$->extra_var.var_declared_list.push_back(make_pair($1->extra_var.carr1,""));

					/*---pasing the assm_code---*/
					$$->extra_var.assm_code = $1->extra_var.assm_code;

				}
	      ;


%%
int main(int argc,char *argv[])
{

	FILE* fp;

	if((fp=fopen(argv[1],"r"))==NULL)
	{
		printf("Cannot Open Input File.\n");
		exit(1);
	}

	//logs= fopen("log.txt","w");
	errors= fopen("log.txt","w");

	set_token_symbols();
	yyin=fp;
	yyparse();

  //fprintf(logs,"Total Line: %d\n\n",line_counter-1);
	//fprintf(logs,"Total Error: %d\n\n",error_counter);
	fprintf(errors,"Total Line: %d\n\n",line_counter-1);
  fprintf(errors,"Total Error: %d\n\n",error_counter);

	fclose(yyin);
  fclose(errors);
	//fclose(logs);


	return 0;
}
