# Copyright (c) 2012-2013 - The pycangjie authors
#
# This file is part of pycangjie, the Python bindings to libcangjie.
#
# pycangjie is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# pycangjie is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with pycangjie.  If not, see <http://www.gnu.org/licenses/>.

#from cython.operator cimport preincrement as inc, dereference as deref

cimport _core


cdef class CangjieChar:
    cdef _core.CCangjieChar *cobj

    def __cinit__(self, char *chchar, char *code, uint32_t frequency):
        ret = <int>_core.cangjie_char_new(&self.cobj, chchar, code,
                                          frequency)
        if ret != 0:
            raise MemoryError('Could not allocate memory for a CangjieChar')

    @property
    def chchar(self):
        return self.cobj.chchar.decode("utf-8")

    @property
    def code(self):
        return self.cobj.code.decode("utf-8")

    @property
    def frequency(self):
        return self.cobj.frequency

    def __dealloc__(self):
        if self.cobj is not NULL:
            _core.cangjie_char_free(self.cobj)

    def __str__(self):
        return ("<CangjieChar chchar='%s', code='%s', frequency='%s'>"
                % (self.chchar, self.code, self.frequency))

    def __richcmp__(self, other, op):
        equality = (self.chchar == other.chchar
                and self.code == other.code
                and self.frequency == other.frequency)

        if op == 2:
            return equality

        if op == 3:
            return not equality

        raise NotImplementedError("Only (in)equality is implemented")


cdef class CangjieCharList:
    cdef _core.CCangjieCharList *cobj

    def __cinit__(self):
        self.cobj = NULL

    def __iter__(self):
        cdef _core.CCangjieCharList *iter_ = self.cobj
        if self.cobj == NULL:
            raise StopIteration()

        while True:
            c = iter_.c
            yield CangjieChar(c.chchar, c.code, c.frequency)

            if iter_.next == NULL:
                break

            iter_ = iter_.next

    def __dealloc__(self):
        if self.cobj is not NULL:
            _core.cangjie_char_list_free(self.cobj)


cdef class Cangjie:
    cdef _core.CCangjie *cobj

    def __cinit__(self, _core.CangjieVersion version,
                  _core.CangjieFilter filter_flags):
        """Constructor for the Cangjie class

        The `version` parameter must be one of the available constants in
        the `cangjie.versions` module.

        The `filter_flags` parameter must be a bitwise-AND of one or more of
        the available constants in the `cangjie.filters` module.
        """
        ret = <int>_core.cangjie_new(&self.cobj, version, filter_flags)
        if ret != 0:
            raise MemoryError('Could not allocate memory for a Cangjie')

    @property
    def filter_flags(self):
        return self.cobj.filter_flags

    @property
    def version(self):
        return self.cobj.version

    def get_characters(self, str code):
        l = CangjieCharList()
        b_code = code.encode("utf-8")

        ret = <int>_core.cangjie_get_characters(self.cobj, b_code, &l.cobj)
        if ret != 0:
            # TODO: Exception handling
            pass

        return list(l)

    def get_radical(self, str key):
        b_key = key.encode("utf-8")
        if len(b_key) > 1:
            # TODO: Exception handling
            pass

        # A char is in fact an integer in C
        b_key = ord(b_key)

        cdef const char *radical

        ret = <int>_core.cangjie_get_radical(self.cobj, b_key, &radical)
        if ret != 0:
            # TODO: Exception handling
            pass

        return (<bytes>radical).decode("utf-8")

    def is_input_key(self, str key):
        b_key = key.encode("utf-8")
        if len(b_key) > 1:
            # TODO: Exception handling
            pass

        # A char is in fact an integer in C
        b_key = ord(b_key)

        ret = <int>_core.cangjie_is_input_key(self.cobj, b_key)

        return ret == 0

    def __dealloc__(self):
        if self.cobj is not NULL:
            _core.cangjie_free(self.cobj)
