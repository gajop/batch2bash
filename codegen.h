#ifndef CODEGEN_H
#define CODEGEN_H
#include <string>
#include "command.h"
#include <map>

/* translate a given command
 * comm : command to be translated, round : which part of the translation are we doing
 * most basic commands only have round = 0
 * some, like if have round 0 and 1
 * commands can have more than 2 rounds, f.e if_else has 0, 1 and 2
 * example :
 * echo has only one round, and that's a 1 to 1 translate
 * if <something>
 *    echo <something>
 * will have two rounds for if, one to generate the bash equivalent of if <something> at
 * round 0, and second to close up with the bash equivalent at round 1
 * */
std::string translate(command* comm, int round);
class lookup_commands {
public: 
    lookup_commands();
    std::string get_trans(const std::string& orig);
    bool exists(const std::string& orig);
private:
    std::map<std::string, std::string> comms;
};

#endif
