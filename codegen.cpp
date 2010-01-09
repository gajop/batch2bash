#include "codegen.h"
#include "command.h"
#include <string>

std::string add_args(const std::string& translated_name, command* comm);
std::string add_arg(const std::string& so_far, const argument& arg);

/*
ASSIGN  ln  link file or directory
ATTRIB  chmod   change file permissions
CD  cd  change directory
CHDIR   cd  change directory
CLS clear   clear screen
COMP    diff, comm, cmp file compare
COPY    cp  file copy
Ctl-C   Ctl-C   break (signal)
Ctl-Z   Ctl-D   EOF (end-of-file)
DEL rm  delete file(s)
DELTREE rm -r   delete directory recursively
DIR ls -l   directory listing
ERASE   rm  delete file(s)
EXIT    exit    exit current process
FC  comm, cmp   file compare
FIND    grep    find strings in files
MD  mkdir   make directory
MKDIR   mkdir   make directory
MORE    more    text file paging filter
MOVE    mv  move
PATH    $PATH   path to executables
REN mv  rename (move)
RENAME  mv  rename (move)
RD  rmdir   remove directory
RMDIR   rmdir   remove directory
SORT    sort    sort file
TIME    date    display system time
TYPE    cat output file to stdout
XCOPY   cp  (extended) file copy 
REM # commend
*/

lookup_commands::lookup_commands() {
    std::string orig[] = { "assign", "attrib", "chdir", "cls", "comp", "copy", "del",
        "erase", "fc", "find", "md", "move", "rd", "time", "type", "xcopy","rem", "dir",
        "deltree", "path", "date", "sort","set_line","unset","set"};

    std::string trans[] = { "ln", "attrib", "cd", "clear", "diff", "cp", "rm",
        "rm", "comm", "grep", "mkdir", "mv", "rmdir", "date", "cat", "cp" ,"#","ls -l",
        "rm -r", "export", "date", "sort","env","unset","" };
    int num = 25;
    for (int i = 0; i < num; ++i) {
        comms[orig[i]] = trans[i];
    }
}

bool lookup_commands::exists(const std::string& orig) {
    return comms.count(orig);
}

lookup_commands lookup;


//use it wisely, preferably after having done lookup_commands::exists
std::string lookup_commands::get_trans(const std::string& orig) {
    return comms[orig];
}

// there are three types of commands in general
// 1: have a near 1:1 translation, only putting the command name to lowercase
// 2: have a 1:1 translation minus the command name
// 3: need to be manually translated, on a per-argument basis
// by default, if command isn't of type 3 (and has an explicit translation) a lookup table 
// is checked to see if it's of type 2, otherwise it's assumed of type 1
std::string translate(command* comm, int round, std::vector<command*> prev, int& indent) {
    std::string name = comm->get_name();
    if (name == "if") {
        if (round == 0) {
            ++indent;
            std::string out = "if [[";
            bool not_found = false;
            for (unsigned i = 0; i < comm->get_num_args(); ++i) {
                if (comm->get_argument(i).value == "not") {
                    out += " ! [[";
                    not_found = true;
                } else if (comm->get_argument(i).value == "errorlevel") {
                    out += " $? ==";
                } else if (comm->get_argument(i).value == "exists") {
                    out += " -a";
                } else {
                    out = add_arg(out, comm->get_argument(i));
                }
            }
            if (not_found) {
                out += " ]] ";
            }
            out += " ]]; then";
            return out;
        } else {
            --indent;
            if (prev[prev.size() - 2]->get_name() == "if_else") {
                return "";
            } else {
                return "fi";
            }
        }
    } else if (name == "else") {
        if (round == 0) {
            ++indent;
            return "else";
        } else {
            --indent;
            return "fi";
        }
    } else if (name == "if_else") {
        return "";
    } else if (name == "while") {
        if (round == 0) {
            ++indent;
            std::string out = "while [[";
            bool not_found = false;
            for (unsigned i = 0; i < comm->get_num_args(); ++i) {
                if (comm->get_argument(i).value == "not") {
                    out += " ! [[";
                    not_found = true;
                } else if (comm->get_argument(i).value == "errorlevel") {
                    out += " $? ==";
                } else if (comm->get_argument(i).value == "exists") {
                    out += " -a";
                } else {
                    out = add_arg(out, comm->get_argument(i));
                }
            }
            if (not_found) {
                out += " ]] ";
            }
            out += " ]]; do";
            return out;
        } else {
            --indent;
            return "done";
        }
    } else if (name == "pause"){
        return "echo \"Press enter to continue\"; read ";
    } else if (name == "compound") {
        return ""; //hm
    } else if (name == "set") {
        std::string out;
        for (unsigned i = 0; i < comm->get_num_args(); ++i) {
            out += comm->get_argument(i).value;
        }
        return out;
    } else if (name == "label") {
        return "# unused label: " + comm->get_argument(0).value; 
    } else if (name == "for") {
        if(round == 0 ) {
            std::string out = "for ";
            out = out + comm->get_argument(0).value;
            out = out + " in ";
            for(unsigned int i = 1; i < comm->get_num_args(); i++) {
                out = out + " " + comm->get_argument(i).value;
            }
            ++indent;
            return out + "\ndo";
        } else { 
            --indent;
            return "done";
        }
    }
    if (lookup.exists(name)) {
        return add_args(lookup.get_trans(name), comm);
    }
    return add_args(comm->get_name(), comm);
}


std::string add_args(const std::string& translated_name, command* comm) {
    std::string ret = translated_name;
    for (unsigned i = 0; i < comm->get_num_args(); ++i) {
        argument arg = comm->get_argument(i);
        ret = add_arg(ret, arg);
    }
    return ret;
}

std::string add_arg(const std::string& so_far, const argument& arg) {
    if (arg.type == aOPT) {
        return so_far + " -" + arg.value;
    } else {
        return so_far + " " +  arg.value;
    }
}


options::options(){
    
    std::map<std::string,std::string> opts;
    //del options
    opts["/p"] = "-i";
    opts["/v"] = " ";
    opts["/q"] = "-f";
    options_map["del"] = opts;
    opts.clear();
    //copy options , most make no sense,  or are a default  behaviour 
    opts["/a"] = " ";
    opts["/b"] = " ";
    opts["/v"] = " ";
    opts["/y"] = " ";
    opts["/-y"]= "-i";
    options_map["copy"] = opts;
    opts.clear();
    //deltree options
    opts["/y"] = "-f";
    opts["/v"] = "-v";
    opts["/d"] = "-v";
    opts["/x"] = "--version";
    opts["/z:seriously"] = "--no-preserve-root";
    options_map["deltree"] = opts;
    opts.clear();
    //dir options, most do not have anythin similar in bash
    opts["/p"] = " ";
    opts["/w"] = "-C";
    opts["/a"] = " ";
    opts["/o"] = " ";
    opts["s"] = "-R";
    opts["/b"] = " ";
    opts["/l"] = " ";
    opts["/y"] = " ";
    opts["/4"] = " ";
    options_map["dir"] = opts;
    opts.clear();
    //find options
    opts["/c"] = "-c";
    opts["/i"] = "-i";
    opts["/n"] = "-n";
    opts["/v"] = "-v";
    options_map["find"] = opts;
    opts.clear();
    //more options 
    opts["/t4"] = " ";
    options_map["more"] = opts;
    opts.clear();
    //move options
    opts["/y"] = "-f";
    opts["/-y"]= " ";
    opts["/v"] = " ";
    options_map["move"] = opts;
    opts.clear();
    //fc options NOT DONE!
    opts["/a"] = " ";
    options_map["fc"] = opts;
    opts.clear();
    //date options
    opts["/d"] = " ";
    options_map["date"] = opts;
    opts.clear();
    //time options
    opts["/t"] = " ";
    options_map["time"] = opts;
    opts.clear();
    //sort oprions
    opts["/r"] = "-r";
    opts["/n"] = " ";
    options_map["sort"] = opts;
    opts.clear();
    //set options 
    opts["/c"] = " ";
    opts["/p"] = " ";
    opts["/u"] = " ";
    options_map["set"] = opts;
    opts.clear();
    //
    


}

options opts;

bool translate_options(std::vector<std::string>& options_list, std::string name){
    
    std::vector<std::string> orig_opts;
    std::map<std::string, std::string> opts_map;
    std::string opt;
    opts_map = opts.options_map[name];

    orig_opts = options_list;
    options_list.clear();

    for(unsigned int i = 0; i < orig_opts.size(); ++i){
        if( opts_map.find(orig_opts[i]) == opts_map.end()) return false;
                
        options_list.push_back(opts_map[orig_opts[i]]);
    }
   return true;

}
