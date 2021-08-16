ifeq ($(DEBUG),1)
	GOFLAGS = -debug
endif

run : main.js
	go run . -web $(GOFLAGS) tests/c2h4.png

install : main.js
	go install .

runcap : main.js
	go run . -web $(GOFLAGS) -cap tests/c2h4.cap tests/c2h4.png

main.js : src/Main.elm
	sed -i 's/\t/        /g' src/Main.elm
	elm make src/Main.elm --output=main.js

test:
	go run . -grid 16,16 -cap tests/c2h4.cap -crop 200,400,3000,2800 tests/c2h4.png

help:
	go run . -h

bench:
	go test . -bench 'DrawGrid'

benchprof:
	go test . -bench 'DrawGrid' -cpuprofile profiles/grid.out
