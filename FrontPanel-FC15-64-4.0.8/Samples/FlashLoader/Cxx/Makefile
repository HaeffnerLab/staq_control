PROGRAM = flashloader
CXXFLAGS = -Wall -fPIC
CXX = g++
OBJECTS = \
	flashloader.o \
	okFrontPanelDLL.o

.SUFFIXES: .o .cpp

all: $(PROGRAM)

$(OBJECTS): %.o:%.cpp
	$(CXX) $(CXXFLAGS) -c $<

$(PROGRAM): $(OBJECTS)
	$(CXX) -o $(PROGRAM) $(OBJECTS) $(FRONTPANELLIB) -ldl

clean:
	rm -f *.o $(PROGRAM)

