//
//  proxy_ptr.h
//  CXXProxyKit
//
//  Created by Dmitry Khrykin on 15.09.2020.
//  Copyright © 2020 Dmitry Khrykin. All rights reserved.
//

#ifdef __cplusplus

#ifndef proxy_ptr_h
#define proxy_ptr_h

#include <type_traits>

namespace cxx {

static constexpr bool owning = true;
static constexpr bool non_owning = false;

/**
 A std::unique_ptr-like smart pointer that can switch between owning and non-owning semantics.
 */
template<class T>
class proxy_ptr {
public:
    static_assert(!std::is_same_v<std::remove_cv_t<T>, void>,
                  "cxx::proxy_ptr<void> is not supported. Use cxx::make_proxy_ptr() to make proxy to void *.");

#pragma mark - Setting Ownership Policy

    bool is_owning = false;

#pragma mark - Initialization & Destruction

    explicit proxy_ptr(T *raw_ptr = nullptr, bool owning = non_owning)
    : raw_ptr(raw_ptr),
    is_owning(owning) {}

    proxy_ptr(const proxy_ptr &other) = delete;

    proxy_ptr(proxy_ptr &&other) {
        transfer_ownership_from(other);
    }

    ~proxy_ptr() {
        delete_if_needed();
    }

#pragma mark - Relinquishing the Underlying Raw Pointer

    T *release() {
        auto *old_ptr = raw_ptr;
        raw_ptr = nullptr;
        return old_ptr;
    }

#pragma mark - Accessing the Underlying Raw Pointer

    T *get() const {
        return raw_ptr;
    }

#pragma mark - Operators Overloads

#pragma mark Copy Assignment

    proxy_ptr &operator=(const proxy_ptr &other) = delete;

    proxy_ptr &operator=(T *other_raw_ptr) {
        delete_if_needed();

        raw_ptr = other_raw_ptr;

        return *this;
    }

#pragma mark Move Assignment

    proxy_ptr &operator=(proxy_ptr &&other) {
        transfer_ownership_from(other);

        return *this;
    }

#pragma mark Indirection

    T &operator*() const {
        return *raw_ptr;
    }

    T *operator->() const {
        return raw_ptr;
    }

#pragma mark Bool

    operator bool() const {
        return raw_ptr != nullptr;
    }

#pragma mark Equality

    bool operator==(T *other_raw_ptr) {
        return raw_ptr == other_raw_ptr;
    }

    bool operator!=(T *other_raw_ptr) {
        return raw_ptr != other_raw_ptr;
    }

    bool operator==(const proxy_ptr &other) {
        return raw_ptr == other.get();
    }

    bool operator!=(const proxy_ptr &other) {
        return raw_ptr != other.get();
    }

private:
    T *raw_ptr;

#pragma mark - Transfering Ownership From Another Proxy Pointer

    void transfer_ownership_from(proxy_ptr &other) {
        raw_ptr = other.raw_ptr;
        is_owning = other.is_owning;

        other.release();
    }

#pragma mark - Deleting Underlying Raw Pointer

    void delete_if_needed() {
        if (is_owning) {
            delete raw_ptr;
        }
    }
};

/**
 Creates proxy_ptr from const void *.
 */
template<typename T>
proxy_ptr<const T> make_proxy_ptr(const void *ptr, bool owning) {
    return proxy_ptr(static_cast<const T *>(ptr), owning);
}

/**
 Creates proxy_ptr from void *.
 */
template<typename T>
proxy_ptr<T> make_proxy_ptr(void *ptr, bool owning) {
    return proxy_ptr(static_cast<T *>(ptr), owning);
}

}

#endif /* proxy_ptr_h */

#endif /* __cplusplus */
