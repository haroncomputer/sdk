// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/flags.h"

#include "platform/assert.h"
#include "vm/isolate.h"
#include "vm/json_stream.h"
#include "vm/os.h"
#include "vm/version.h"

namespace dart {

DEFINE_FLAG(bool, print_flags, false, "Print flags as they are being parsed.");
DEFINE_FLAG(bool,
            ignore_unrecognized_flags,
            false,
            "Ignore unrecognized flags.");

#define PRODUCT_FLAG_MACRO(name, type, default_value, comment)                 \
  type FLAG_##name =                                                           \
      Flags::Register_##type(&FLAG_##name, #name, default_value, comment);

#if defined(DEBUG)
#define DEBUG_FLAG_MACRO(name, type, default_value, comment)                   \
  type FLAG_##name =                                                           \
      Flags::Register_##type(&FLAG_##name, #name, default_value, comment);
#else  // defined(DEBUG)
#define DEBUG_FLAG_MACRO(name, type, default_value, comment)
#endif  // defined(DEBUG)

#if defined(PRODUCT) && defined(DART_PRECOMPILED_RUNTIME)
// Nothing to be done for the product flag definitions.
#define RELEASE_FLAG_MACRO(name, product_value, type, default_value, comment)
// Nothing to be done for the precompilation flag definitions.
#define PRECOMPILE_FLAG_MACRO(name, pre_value, product_value, type,            \
                              default_value, comment)

#elif defined(PRODUCT)  // !PRECOMPILED
// Nothing to be done for the product flag definitions.
#define RELEASE_FLAG_MACRO(name, product_value, type, default_value, comment)
// Nothing to be done for the precompilation flag definitions.
#define PRECOMPILE_FLAG_MACRO(name, pre_value, product_value, type,            \
                              default_value, comment)

#elif defined(DART_PRECOMPILED_RUNTIME)  // !PRODUCT
#define RELEASE_FLAG_MACRO(name, product_value, type, default_value, comment)  \
  type FLAG_##name =                                                           \
      Flags::Register_##type(&FLAG_##name, #name, default_value, comment);
// Nothing to be done for the precompilation flag definitions.
#define PRECOMPILE_FLAG_MACRO(name, pre_value, product_value, type,            \
                              default_value, comment)

#else  // !PRODUCT && !PRECOMPILED
#define RELEASE_FLAG_MACRO(name, product_value, type, default_value, comment)  \
  type FLAG_##name =                                                           \
      Flags::Register_##type(&FLAG_##name, #name, default_value, comment);
#define PRECOMPILE_FLAG_MACRO(name, pre_value, product_value, type,            \
                              default_value, comment)                          \
  type FLAG_##name =                                                           \
      Flags::Register_##type(&FLAG_##name, #name, default_value, comment);
#endif

// Define all of the non-product flags here.
FLAG_LIST(PRODUCT_FLAG_MACRO,
          RELEASE_FLAG_MACRO,
          PRECOMPILE_FLAG_MACRO,
          DEBUG_FLAG_MACRO)

#undef PRODUCT_FLAG_MACRO
#undef RELEASE_FLAG_MACRO
#undef PRECOMPILE_FLAG_MACRO
#undef DEBUG_FLAG_MACRO

#if defined(DART_PRECOMPILER)
#if defined(TARGET_USES_THREAD_SANITIZER)
constexpr bool kDefaultTargetThreadSanitizer = true;
#else
constexpr bool kDefaultTargetThreadSanitizer = false;
#endif
DEFINE_FLAG(bool,
            target_thread_sanitizer,
            kDefaultTargetThreadSanitizer,
            "Generate Dart code compatible with Thread Sanitizer");
#if defined(TARGET_USES_MEMORY_SANITIZER)
constexpr bool kDefaultTargetMemorySanitizer = true;
#else
constexpr bool kDefaultTargetMemorySanitizer = false;
#endif
DEFINE_FLAG(bool,
            target_memory_sanitizer,
            kDefaultTargetMemorySanitizer,
            "Generate Dart code compatible with Memory Sanitizer");
#endif

static bool IsMainOrDevChannel() {
  return strstr("|main|dev|", Version::Channel()) != nullptr;
}

static void EnableExperimentSharedData(bool value) {
  if (value && !IsMainOrDevChannel()) {
    FATAL(
        "Shared memory multithreading in only available for "
        "experimentation in dev or main");
  }
  dart::FLAG_experimental_shared_data = value;
}

bool FLAG_experimental_shared_data = false;
DEFINE_FLAG_HANDLER(EnableExperimentSharedData,
                    experimental_shared_data,
                    "Enable experiment to share data between isolates.");

bool Flags::initialized_ = false;

// List of registered flags.
Flag** Flags::flags_ = nullptr;
intptr_t Flags::capacity_ = 0;
intptr_t Flags::num_flags_ = 0;

class Flag {
 public:
  enum FlagType {
    kBoolean,
    kInteger,
    kUint64,
    kString,
    kFlagHandler,
    kOptionHandler,
    kNumFlagTypes
  };

  Flag(const char* name, const char* comment, void* addr, FlagType type)
      : name_(name), comment_(comment), addr_(addr), type_(type) {}
  Flag(const char* name, const char* comment, FlagHandler handler)
      : name_(name),
        comment_(comment),
        flag_handler_(handler),
        type_(kFlagHandler) {}
  Flag(const char* name, const char* comment, OptionHandler handler)
      : name_(name),
        comment_(comment),
        option_handler_(handler),
        type_(kOptionHandler) {}

  void Print() {
    if (IsUnrecognized()) {
      OS::PrintErr("%s: unrecognized\n", name_);
      return;
    }
    switch (type_) {
      case kBoolean: {
        OS::Print("%s: %s (%s)\n", name_, *this->bool_ptr_ ? "true" : "false",
                  comment_);
        break;
      }
      case kInteger: {
        OS::Print("%s: %d (%s)\n", name_, *this->int_ptr_, comment_);
        break;
      }
      case kUint64: {
        OS::Print("%s: %" Pu64 " (%s)\n", name_, *this->uint64_ptr_, comment_);
        break;
      }
      case kString: {
        if (*this->charp_ptr_ != nullptr) {
          OS::Print("%s: '%s' (%s)\n", name_, *this->charp_ptr_, comment_);
        } else {
          OS::Print("%s: (null) (%s)\n", name_, comment_);
        }
        break;
      }
      case kOptionHandler:
      case kFlagHandler: {
        OS::Print("%s: (%s)\n", name_, comment_);
        break;
      }
      default:
        UNREACHABLE();
        break;
    }
  }

  bool IsUnrecognized() const {
    return (type_ == kBoolean) && (bool_ptr_ == nullptr);
  }

  const char* name_;
  const char* comment_;

  // For kString, kOptionHandler, kFlagHandler flags this stores the copy
  // of the original flag value passed to SetFlagFromString
  CStringUniquePtr string_value_;
  union {
    void* addr_;
    bool* bool_ptr_;
    int* int_ptr_;
    uint64_t* uint64_ptr_;
    charp* charp_ptr_;
    FlagHandler flag_handler_;
    OptionHandler option_handler_;
  };
  const FlagType type_;
  bool changed_ = false;
};

Flag* Flags::Lookup(const char* name) {
  for (intptr_t i = 0; i < num_flags_; i++) {
    Flag* flag = flags_[i];
    if (strcmp(flag->name_, name) == 0) {
      return flag;
    }
  }
  return nullptr;
}

bool Flags::IsSet(const char* name) {
  Flag* flag = Lookup(name);
  return (flag != nullptr) && (flag->type_ == Flag::kBoolean) &&
         (flag->bool_ptr_ != nullptr) && (*flag->bool_ptr_ == true);
}

void Flags::Cleanup() {
  ASSERT(initialized_);
  initialized_ = false;
}

void Flags::AddFlag(Flag* flag) {
  ASSERT(!initialized_);
  if (num_flags_ == capacity_) {
    if (flags_ == nullptr) {
      capacity_ = 256;
      flags_ = new Flag*[capacity_];
    } else {
      intptr_t new_capacity = capacity_ * 2;
      Flag** new_flags = new Flag*[new_capacity];
      for (intptr_t i = 0; i < num_flags_; i++) {
        new_flags[i] = flags_[i];
      }
      delete[] flags_;
      flags_ = new_flags;
      capacity_ = new_capacity;
    }
  }
  flags_[num_flags_++] = flag;
}

bool Flags::Register_bool(bool* addr,
                          const char* name,
                          bool default_value,
                          const char* comment) {
  Flag* flag = Lookup(name);
  if (flag != nullptr) {
    ASSERT(flag->IsUnrecognized());
    return default_value;
  }
  flag = new Flag(name, comment, addr, Flag::kBoolean);
  AddFlag(flag);
  return default_value;
}

int Flags::Register_int(int* addr,
                        const char* name,
                        int default_value,
                        const char* comment) {
  ASSERT(Lookup(name) == nullptr);

  Flag* flag = new Flag(name, comment, addr, Flag::kInteger);
  AddFlag(flag);

  return default_value;
}

uint64_t Flags::Register_uint64_t(uint64_t* addr,
                                  const char* name,
                                  uint64_t default_value,
                                  const char* comment) {
  ASSERT(Lookup(name) == nullptr);

  Flag* flag = new Flag(name, comment, addr, Flag::kUint64);
  AddFlag(flag);

  return default_value;
}

const char* Flags::Register_charp(charp* addr,
                                  const char* name,
                                  const char* default_value,
                                  const char* comment) {
  ASSERT(Lookup(name) == nullptr);
  Flag* flag = new Flag(name, comment, addr, Flag::kString);
  AddFlag(flag);
  return default_value;
}

bool Flags::RegisterFlagHandler(FlagHandler handler,
                                const char* name,
                                const char* comment) {
  ASSERT(Lookup(name) == nullptr);
  Flag* flag = new Flag(name, comment, handler);
  AddFlag(flag);
  return false;
}

bool Flags::RegisterOptionHandler(OptionHandler handler,
                                  const char* name,
                                  const char* comment) {
  ASSERT(Lookup(name) == nullptr);
  Flag* flag = new Flag(name, comment, handler);
  AddFlag(flag);
  return false;
}

static void Normalize(char* s) {
  intptr_t len = strlen(s);
  for (intptr_t i = 0; i < len; i++) {
    if (s[i] == '-') {
      s[i] = '_';
    }
  }
}

bool Flags::SetFlagFromString(Flag* flag, const char* argument) {
  ASSERT(!flag->IsUnrecognized());
  switch (flag->type_) {
    case Flag::kBoolean: {
      if (strcmp(argument, "true") == 0) {
        *flag->bool_ptr_ = true;
      } else if (strcmp(argument, "false") == 0) {
        *flag->bool_ptr_ = false;
      } else {
        return false;
      }
      break;
    }
    case Flag::kString: {
      flag->string_value_.reset(argument == nullptr ? nullptr
                                                    : Utils::StrDup(argument));
      *flag->charp_ptr_ = flag->string_value_.get();
      break;
    }
    case Flag::kInteger: {
      char* endptr = nullptr;
      const intptr_t len = strlen(argument);
      int base = 10;
      if ((len > 2) && (argument[0] == '0') && (argument[1] == 'x')) {
        base = 16;
      }
      int val = strtol(argument, &endptr, base);
      if (endptr == argument + len) {
        *flag->int_ptr_ = val;
      } else {
        return false;
      }
      break;
    }
    case Flag::kUint64: {
      char* endptr = nullptr;
      const intptr_t len = strlen(argument);
      int base = 10;
      if ((len > 2) && (argument[0] == '0') && (argument[1] == 'x')) {
        base = 16;
      }
      int64_t val = strtoll(argument, &endptr, base);
      if (endptr == argument + len) {
        *flag->uint64_ptr_ = static_cast<uint64_t>(val);
      } else {
        return false;
      }
      break;
    }
    case Flag::kFlagHandler: {
      if (strcmp(argument, "true") == 0) {
        (flag->flag_handler_)(true);
      } else if (strcmp(argument, "false") == 0) {
        (flag->flag_handler_)(false);
      } else {
        return false;
      }
      flag->string_value_.reset(Utils::StrDup(argument));
      break;
    }
    case Flag::kOptionHandler: {
      flag->string_value_.reset(Utils::StrDup(argument));
      (flag->option_handler_)(argument);
      break;
    }
    default: {
      UNREACHABLE();
      return false;
    }
  }
  flag->changed_ = true;
  return true;
}

void Flags::Parse(const char* option) {
  // Find the beginning of the option argument, if it exists.
  const char* equals = option;
  while ((*equals != '\0') && (*equals != '=')) {
    equals++;
  }

  const char* argument = nullptr;

  // Determine if this is an option argument.
  if (*equals != '=') {
    // No explicit option argument. Determine if there is a "no_" prefix
    // preceding the name.
    const char* const kNo1Prefix = "no_";
    const char* const kNo2Prefix = "no-";
    const intptr_t kNo1PrefixLen = strlen(kNo1Prefix);
    const intptr_t kNo2PrefixLen = strlen(kNo2Prefix);
    if (strncmp(option, kNo1Prefix, kNo1PrefixLen) == 0) {
      option += kNo1PrefixLen;  // Skip the "no_" when looking up the name.
      argument = "false";
    } else if (strncmp(option, kNo2Prefix, kNo2PrefixLen) == 0) {
      option += kNo2PrefixLen;  // Skip the "no-" when looking up the name.
      argument = "false";
    } else {
      argument = "true";
    }
  } else {
    // The argument for the option starts right after the equals sign.
    argument = equals + 1;
  }

  // Initialize the flag name.
  intptr_t name_len = equals - option;
  char* name = new char[name_len + 1];
  strncpy(name, option, name_len);
  name[name_len] = '\0';
  Normalize(name);

  Flag* flag = Flags::Lookup(name);
  if (flag == nullptr) {
    // Collect unrecognized flags.
    char* new_flag = new char[name_len + 1];
    strncpy(new_flag, option, name_len);
    new_flag[name_len] = '\0';
    Normalize(new_flag);  // Or a later lookup may fail.
    Flags::Register_bool(nullptr, new_flag, true, nullptr);
  } else {
    // Only set values for recognized flags, skip collected
    // unrecognized flags.
    if (!flag->IsUnrecognized()) {
      if (!SetFlagFromString(flag, argument)) {
        OS::PrintErr("Ignoring flag: %s is an invalid value for flag %s\n",
                     argument, name);
      }
    }
  }

  delete[] name;
}

static bool IsValidFlag(const char* name,
                        const char* prefix,
                        intptr_t prefix_length) {
  intptr_t name_length = strlen(name);
  return ((name_length > prefix_length) &&
          (strncmp(name, prefix, prefix_length) == 0));
}

int Flags::CompareFlagNames(const void* left, const void* right) {
  const Flag* left_flag = *reinterpret_cast<const Flag* const*>(left);
  const Flag* right_flag = *reinterpret_cast<const Flag* const*>(right);
  return strcmp(left_flag->name_, right_flag->name_);
}

char* Flags::ProcessCommandLineFlags(int number_of_vm_flags,
                                     const char** vm_flags) {
  if (initialized_) {
    return Utils::StrDup("Flags already set");
  }

  qsort(flags_, num_flags_, sizeof flags_[0], CompareFlagNames);

  const char* const kPrefix = "--";
  const intptr_t kPrefixLen = strlen(kPrefix);

  int i = 0;
  while ((i < number_of_vm_flags) &&
         IsValidFlag(vm_flags[i], kPrefix, kPrefixLen)) {
    const char* option = vm_flags[i] + kPrefixLen;
    Parse(option);
    i++;
  }

  if (!FLAG_ignore_unrecognized_flags) {
    int unrecognized_count = 0;
    TextBuffer error(64);
    for (intptr_t j = 0; j < num_flags_; j++) {
      Flag* flag = flags_[j];
      if (flag->IsUnrecognized()) {
        if (unrecognized_count == 0) {
          error.Printf("Unrecognized flags: %s", flag->name_);
        } else {
          error.Printf(", %s", flag->name_);
        }
        unrecognized_count++;
      }
    }
    if (unrecognized_count > 0) {
      return error.Steal();
    }
  }
  if (FLAG_print_flags) {
    PrintFlags();
  }

  initialized_ = true;
  return nullptr;
}

bool Flags::SetFlag(const char* name, const char* value, const char** error) {
  Flag* flag = Lookup(name);
  if (flag == nullptr) {
    *error = "Cannot set flag: flag not found";
    return false;
  }
  if (!SetFlagFromString(flag, value)) {
    *error = "Cannot set flag: invalid value";
    return false;
  }
  return true;
}

void Flags::PrintFlags() {
  OS::Print("Flag settings:\n");
  for (intptr_t i = 0; i < num_flags_; ++i) {
    flags_[i]->Print();
  }
}

#ifndef PRODUCT
void Flags::PrintFlagToJSONArray(JSONArray* jsarr, const Flag* flag) {
  if (flag->IsUnrecognized()) {
    return;
  }
  JSONObject jsflag(jsarr);
  jsflag.AddProperty("name", flag->name_);
  jsflag.AddProperty("comment", flag->comment_);
  jsflag.AddProperty("modified", flag->changed_);
  switch (flag->type_) {
    case Flag::kBoolean: {
      jsflag.AddProperty("_flagType", "Bool");
      jsflag.AddProperty("valueAsString",
                         (*flag->bool_ptr_ ? "true" : "false"));
      break;
    }
    case Flag::kInteger: {
      jsflag.AddProperty("_flagType", "Int");
      jsflag.AddPropertyF("valueAsString", "%d", *flag->int_ptr_);
      break;
    }
    case Flag::kUint64: {
      jsflag.AddProperty("_flagType", "UInt64");
      jsflag.AddPropertyF("valueAsString", "%" Pu64, *flag->uint64_ptr_);
      break;
    }
    case Flag::kString: {
      jsflag.AddProperty("_flagType", "String");
      if (flag->charp_ptr_ != nullptr) {
        jsflag.AddPropertyF("valueAsString", "%s", *flag->charp_ptr_);
      } else {
        // valueAsString missing means nullptr.
      }
      break;
    }
    case Flag::kFlagHandler: {
      jsflag.AddProperty("_flagType", "Bool");
      const char* value = flag->string_value_.get();
      jsflag.AddProperty("valueAsString", value == nullptr ? "false" : value);
      break;
    }
    case Flag::kOptionHandler: {
      jsflag.AddProperty("_flagType", "String");
      if (flag->string_value_ != nullptr) {
        jsflag.AddProperty("valueAsString", flag->string_value_.get());
      } else {
        // valueAsString missing means nullptr.
      }
      break;
    }
    default:
      UNREACHABLE();
      break;
  }
}

void Flags::PrintJSON(JSONStream* js) {
  JSONObject jsobj(js);
  jsobj.AddProperty("type", "FlagList");
  JSONArray jsarr(&jsobj, "flags");
  for (intptr_t i = 0; i < num_flags_; ++i) {
    PrintFlagToJSONArray(&jsarr, flags_[i]);
  }
}
#endif  // !PRODUCT

}  // namespace dart
