#ifndef __UTILITY_HPP
#define __UTILITY_HPP

#include <sstream>
#include <string>
#include <iostream>

template <typename elType>
inline std::string toString(const elType& in){
	std::ostringstream out;
	out << in;
	return out.str();
}
#endif
