PROGRAM = RAMTester
CXX = g++
OBJECTS = \
	RAMTester.o \
	mt_random.o \
	okFrontPanelDLL.o

.SUFFIXES: .o .cpp

all: $(PROGRAM)

$(OBJECTS): %.o:%.cpp
	$(CXX) -fPIC -c $<

$(PROGRAM): $(OBJECTS)
	$(CXX) -o $(PROGRAM) $(OBJECTS) $(FRONTPANELLIB) -ldl

clean:
	rm -f *.o $(PROGRAM)

