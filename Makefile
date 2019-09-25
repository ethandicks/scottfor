
# compiler
FORTRAN = gfortran

# compiler flags
FFLAGS = -std=legacy -pedantic

# program name
PROGRAM = scottfor

# sources
SOURCE = $(PROGRAM).f

all: $(PROGRAM)

$(PROGRAM): $(SOURCE)
	$(FORTRAN) $(FFLAGS) -o $(PROGRAM) $(SOURCE)

clean:
	rm -f *.o $(PROGRAM)
