PROGRAM = DESTester
CXX = g++
OBJECTS = \
	DESTester.o \
	okFrontPanelDLL.o

.SUFFIXES: .o .cpp

all: $(PROGRAM)

$(OBJECTS): %.o:%.cpp
	$(CXX) -fPIC -c $<

$(PROGRAM): $(OBJECTS)
	$(CXX) -o $(PROGRAM) $(OBJECTS) -ldl

clean:
	rm -f *.o $(PROGRAM)

