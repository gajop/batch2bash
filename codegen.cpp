#include "codegen.h"
#include "command.h"
#include <string>

std::string add_args(const std::string& translated_name, command* comm);
std::string add_arg(const std::string& so_far, const argument& arg);

lookup_commands::lookup_commands() {
    std::string orig[] = { "assign", "attrib", "chdir", "cls", "comp", "copy", "del",
        "erase", "fc", "find", "md", "move", "rd", "time", "type", "xcopy","rem", "dir",
        "deltree", "path", "date", "sort","set_line","unset","set","color"};

    std::string trans[] = { "ln", "attrib", "cd", "clear", "diff", "cp", "rm",
        "rm", "comm", "grep", "mkdir", "mv", "rmdir", "date", "cat", "cp" ,"#","ls -l",
        "rm -r", "export", "date", "sort","env","unset","","echo -ne " };
    int num = 26;
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
            for (unsigned i = 0; i < comm->get_num_args(); ++i) {
                if (comm->get_argument(i).value == "not") {
                    out += " ! ";
                } else if (comm->get_argument(i).value == "errorlevel") {
                    out += std::string(" $? ") + " -ge ";
                } else if (comm->get_argument(i).value == "exists") {
                    out += " -a";
                } else {
                    out = add_arg(out, comm->get_argument(i));
                }
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
            for (unsigned i = 0; i < comm->get_num_args(); ++i) {
                if (comm->get_argument(i).value == "not") {
                    out += " ! ";
                } else if (comm->get_argument(i).value == "errorlevel") {
                    out += std::string(" $? ") + " -ge ";
                } else if (comm->get_argument(i).value == "exists") {
                    out += " -a";
                } else {
                    out = add_arg(out, comm->get_argument(i));
                }
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
    } else if (name == "call"){
        return "./" + comm->get_argument(0).value;
    } else if (name == "rd") {
        int rm = 0;
        for (unsigned i = 0; i < comm->get_num_args(); ++i) {
            if (comm->get_argument(i).type == aOPT) {
                rm = 1;
                break;
            }
        }
        if (rm) {
            return add_args("rm", comm);
        } else {
            return add_args("rmdir", comm);
        }
    } else if (name == "drive") {
        return "";
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
        if(arg.type == aOPT) {
            if(arg.value[0] == '/'){
                arg.value[0] = '-';
            }
        }
        ret = add_arg(ret, arg);
    }
    return ret;
}

std::string add_arg(const std::string& so_far, const argument& arg) {
    return so_far + " " + arg.value;
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
    opts["/s"] = "-R";
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
    opts["/t"] = " ";
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
    //color codes translation
    //text colors
    opts["t0"] = "\'\\E[0;30m\'";
    opts["t1"] = "\'\\E[0;34m\'";
    opts["t2"] = "\'\\E[0;32m\'";
    opts["t3"] = "\'\\E[0;36m\'";
    opts["t4"] = "\'\\E[0;31m\'";
    opts["t5"] = "\'\\E[0;35m\'";
    opts["t6"] = "\'\\E[1;33m\'";
    opts["t7"] = "\'\\E[1;37m\'";
    opts["t8"] = "\'\\E[0;37m\'";
    opts["t9"] = "\'\\E[1;34m\'";
    opts["ta"] = "\'\\E[1;32m\'";
    opts["tb"] = "\'\\E[1;36m\'";
    opts["tc"] = "\'\\E[1;31m\'";
    opts["td"] = "\'\\E[1;35m\'";
    opts["te"] = "\'\\E[1;33m\'";
    opts["tf"] = "\'\\E[1;37m\'";
    //background colors
    opts["b0"] = "\'\\E[0;40m\'";
    opts["b1"] = "\'\\E[0;44m\'";
    opts["b2"] = "\'\\E[0;42m\'";
    opts["b3"] = "\'\\E[0;46m\'";
    opts["b4"] = "\'\\E[0;41m\'";
    opts["b5"] = "\'\\E[0;45m\'";
    opts["b6"] = "\'\\E[1;43m\'";
    opts["b7"] = "\'\\E[1;47m\'";
    opts["b8"] = "\'\\E[0;47m\'";
    opts["b9"] = "\'\\E[1;44m\'";
    opts["ba"] = "\'\\E[1;42m\'";
    opts["bb"] = "\'\\E[1;46m\'";
    opts["bc"] = "\'\\E[1;41m\'";
    opts["bd"] = "\'\\E[1;45m\'";
    opts["be"] = "\'\\E[1;43m\'";
    opts["bf"] = "\'\\E[1;47m\'";
    options_map["color"] = opts;
    opts.clear();
    //rd options
    opts["/s"] = "-r";
    opts["/q"] = "-f";
    options_map["rd"] = opts;
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
