dart run coverage:test_with_coverage && genhtml -p ${PWD}/lib -o coverage coverage/lcov.info && open coverage/index.html