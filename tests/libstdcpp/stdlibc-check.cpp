#include <iostream>
#include <string>
#include <vector>
#include <stdexcept>

int main() {
    // Uses std::string, std::vector, std::exception — all from libstdc++
    std::vector<std::string> messages = {
        "Hello from libstdc++!",
        "This binary was linked against the C++ standard library.",
        "If you see this, libstdc++ is present and working."
    };

    for (const auto& msg : messages) {
        std::cout << msg << std::endl;
    }

    try {
        throw std::runtime_error("libstdc++ exception handling works too!");
    } catch (const std::exception& e) {
        std::cout << "Caught: " << e.what() << std::endl;
    }

    return 0;
}