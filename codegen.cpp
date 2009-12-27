#include "codegen.h"
#include "command.h"
#include <string>

std::string add_args(const std::string& translated_name, command* comm);
std::string add_arg(const std::string& so_far, const argument& arg);
/*
ASSIGN	ln	link file or directory
ATTRIB	chmod	change file permissions
CD	cd	change directory
CHDIR	cd	change directory
CLS	clear	clear screen
COMP	diff, comm, cmp	file compare
COPY	cp	file copy
Ctl-C	Ctl-C	break (signal)
Ctl-Z	Ctl-D	EOF (end-of-file)
DEL	rm	delete file(s)
DELTREE	rm -rf	delete directory recursively
DIR	ls -l	directory listing
ERASE	rm	delete file(s)
EXIT	exit	exit current process
FC	comm, cmp	file compare
FIND	grep	find strings in files
MD	mkdir	make directory
MKDIR	mkdir	make directory
MORE	more	text file paging filter
MOVE	mv	move
PATH	$PATH	path to executables
REN	mv	rename (move)
RENAME	mv	rename (move)
RD	rmdir	remove directory
RMDIR	rmdir	remove directory
SORT	sort	sort file
TIME	date	display system time
TYPE	cat	output file to stdout
XCOPY	cp	(extended) file copy */
lookup_commands::lookup_commands() {
    std::string orig[] = { "assign", "attrib", "chdir", "cls", "comp", "copy", "del",
        "erase", "fc", "find", "md", "move", "rd", "time", "type", "xcopy" };
    std::string trans[] = { "ln", "attrib", "cd", "clear", "diff", "cp", "rm",
        "rm", "comm", "grep", "mkdir", "mv", "rmdir", "date", "cat", "cp" };
    int num = 16;
    for (int i = 0; i < 16; ++i) {
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
std::string translate(command* comm, int round) {
    std::string name = comm->get_name();
    if (name == "if") {
        if (round == 0) {
            return add_args("if", comm);
        } else {
            return "fi";
        }
    } else if (name == "else") {
        if (round == 0) {
            return "else";
        } else {
            return "fi";
        }
    } else if (name == "if_else") {
        return "";
    } else if (name == "while") {
        if (round == 0) {
            return add_args("while", comm);
        } else {
            return "done";
        }
    } else if (name == "compound") {
        if (round == 0) {
            return "("; //uhm lol no
        } else if (round == comm->get_num_children()) {
            return ")";
        } else {
            return "";
        }
    }
    if (lookup.exists(name)) {
        return add_args(lookup.get_trans(name), comm);
    }
    return add_args(comm->get_name(), comm);
}


std::string add_args(const std::string& translated_name, command* comm) {
    std::string ret = translated_name;
    for (int i = 0; i < comm->get_num_args(); ++i) {
        argument arg = comm->get_argument(i);
        ret = add_arg(ret, arg);
    }
    return ret;
}

std::string add_arg(const std::string& so_far, const argument& arg) {
    return so_far + " " + arg.value;
}
