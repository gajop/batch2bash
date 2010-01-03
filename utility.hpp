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

template<class T>
T fromString(const std::string& s) {
     std::istringstream stream (s);
     T t;
     stream >> t;
     return t;
}
#endif
