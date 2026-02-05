#pragma once
#include <string>

struct Cookie {
  std::string domain;
  std::string name;
  std::string value;

  bool operator==(const Cookie &other) const;
  bool operator!=(const Cookie &other) const;
};
