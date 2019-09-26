C
C SCOTTFOR - FORTRAN INTERPRETER FOR SCOTT ADAMS' TEXT ADVENTURES
C
C CURRENTLY IMPLEMENTED USING MODERN FORTRAN (F77)
C
C ETHAN DICKS <ETHAN.DICKS@GMAIL.COM>
C
C

       INTEGER N, IL, CL, NL, RL, MX, AR, TT, LN, LT, ML, TR
       INTEGER PRINT_HEADER, PRINT_WORDS, PRINT_VOCAB, PRINT_ACTIONS
       INTEGER PRINT_ROOMS, PRINT_MSG, PRINT_ITEMS, PPRINT_ACTIONS
       INTEGER VERB, NOUN, WORD_LEN, WORD_FIRST, WORD_LAST, STRLEN
       INTEGER IS_SYN, RM_LINES, MSG_LINES
       INTEGER W(5), LL(5)
       INTEGER AC(4)
       INTEGER C(280, 8)
       INTEGER RM(40, 6)

       CHARACTER(8) WORD, RAW_WORD
       CHARACTER(80)  RM_BUF(3)
       CHARACTER(100) MSG_BUF(5)
       CHARACTER(5) NOUNS(90)
       CHARACTER(5) VERBS(90)
       CHARACTER(80) RS(40)
C   ALLOCATE SPACE FOR SHORT MESSAGE STRINGS FOR NOW
       CHARACTER(100) MS(100)

C   TRACE/DEBUGGING FLAGS
       PRINT_HEADER = 1
       PRINT_WORDS = 0
       PRINT_VOCAB = 0
       PRINT_ACTIONS = 0
       PPRINT_ACTIONS = 0
       PRINT_ROOMS = 0
       PRINT_MSG = 0
       PRINT_ITEMS = 0

       OPEN (UNIT=2, FILE="adv02.dat", STATUS='old', ACTION='read')


C   READ GAME HEADER

110    FORMAT (I6)
       READ (2, 110) N, IL, CL, NL, RL, MX, AR, TT, LN, LT, ML, TR

C   DISPLAY STATS FROM GAME HEADER

210    FORMAT (A15, I5)

       IF (PRINT_HEADER .NE. 0) THEN
         PRINT 210, 'STRING BYTES:', N
         PRINT 210, 'ITEM COUNT:', IL
         PRINT 210, 'ACTION COUNT:', CL
         PRINT 210, 'VOCAB COUNT:', NL
         PRINT 210, 'ROOM COUNT:', RL
         PRINT 210, 'CARRY MAX:', MX
         PRINT 210, 'START ROOM:', AR
         PRINT 210, 'TREASURE COUNT:', TT 
         PRINT 210, 'WORD LENGTH:', LN
         PRINT 210, 'LIGHT TURNS:', LT
         PRINT 210, 'MSG COUNT:', ML
         PRINT 210, 'TREASURE ROOM:', TR
       ENDIF 

C   READ GAME LOGIC TABLE

       DO 320 I=1, CL+1
           DO 310 J=1, 8
               READ (2, 110) C(I, J)
310    CONTINUE

C   DISPLAY ACTIONS WITH NUMBERED VERBS AND NOUNS

220    FORMAT (A, I3, A, I3, A, I3)
230    FORMAT (A, I3, A, I3, A)
240    FORMAT (5(I3, I3))
250    FORMAT (4(I5))
       VERB = C(I, 1) / 150
       NOUN = C(I, 1) - 150 * VERB
       IF (PRINT_ACTIONS .NE. 0) THEN
         IF (VERB .EQ. 0) THEN
           PRINT 230, '[', I, ']  AUTO ', NOUN, '%'
         ELSE
           PRINT 220, '[', I, ']  VERB #', VERB, ' NOUN #', NOUN
         ENDIF
       ENDIF

       DO 330 J=1, 5
         LL(J) = C(I,J+1) / 20
         W(J) = C(I, J+1) - 20 * LL(J)
330    CONTINUE

       IF (PRINT_ACTIONS .NE. 0) THEN
         DO 340 J=1, 5
           CALL TEST_PRINT(W(J), LL(J))
340      CONTINUE
       ENDIF

       DO 350 J=0, 1
         AC(J*2+1) = C(I, J+7) / 150
         AC(J*2+2) = C(I, J+7) - 150 * AC(J*2+1)
350    CONTINUE

       IF (PRINT_ACTIONS .NE. 0) THEN
         DO 360 J=1, 4
           CALL ACTION_PRINT(AC(J))
360      CONTINUE
       ENDIF

320    CONTINUE

C   READ VOCABULARY

380    FORMAT (A)
382    FORMAT (A, I3, A, A, A, A)

       DO 370 I=1, 2*(NL+1)
         READ (2, 380) RAW_WORD
C   GET ACTUAL STRING LENGTH
         STRLEN = LEN(RAW_WORD)
         DO WHILE (RAW_WORD(STRLEN:STRLEN) .EQ. ' ') 
           STRLEN = STRLEN - 1 
         ENDDO
C   STRIP OFF LEADING QUOTE IF PRESENT
         WORD_FIRST = 1
         IF (RAW_WORD(1:1) .EQ. '"') THEN
           WORD_FIRST = 2
         ENDIF
C   POINT PAST '*' IF PRESENT
         IS_SYN = 0
         IF (RAW_WORD(WORD_FIRST:WORD_FIRST) .EQ. '*') THEN
           WORD_FIRST = WORD_FIRST + 1
          IS_SYN = 1
         ENDIF
C   CHECK FOR TRAILING '"' TO CATCH SHORT WORDS
         WORD_LAST = STRLEN
         IF (RAW_WORD(WORD_LAST:WORD_LAST) .EQ. '"') THEN
           WORD_LAST = WORD_LAST - 1
         ENDIF
C   CHECK FOR VOCAB LENGTH
         IF (WORD_LAST - WORD_FIRST .GE. LN) THEN
           WORD_LAST = LN + 1
         ENDIF
C   CHECK FOR SYNONYMS (STARTS WITH '*')
         IF (IS_SYN .EQ. 1) THEN
           WORD_FIRST = WORD_FIRST - 1
         ENDIF
C   COPY JUST THE WORD FROM THE RAW BUFFER
         WORD = RAW_WORD(WORD_FIRST:WORD_LAST)

         IF (PRINT_VOCAB .NE. 0) THEN
           PRINT 382, 'WORD #', I, ' ', WORD
         ENDIF

         IF (IAND(I, 1) .EQ. 1) THEN
           VERBS(I/2+1) = WORD
         ELSE 
           NOUNS(I/2) = WORD 
         ENDIF
370    CONTINUE

C DISPLAY VOCABUARY

       IF (PRINT_VOCAB .NE. 0) THEN
         DO 390 I=1, NL+1
           PRINT 382, '# ',I, '  VERB: ', VERBS(I), '  NOUN: ', NOUNS(I)
390      CONTINUE
       ENDIF

C READ ROOMS

400    FORMAT (I3)
405    FORMAT (A)
406    FORMAT (A, I3, A, I3, A)
407    FORMAT (6I3, A)
       DO 410 I=1, RL+1
         DO 420 J=1, 6
           READ (2, 400) RM(I, J)
420      CONTINUE

C   READ UP TO 3 LINES FOR ONE STRING
         DO 425 J=1,3
           RM_BUF(J) = ""
425      CONTINUE
         DO 430 RM_LINES=1,3
           READ (2, 405) RM_BUF(RM_LINES)
C   CHECK FOR ADDITIONAL LINES FOR THIS SAME MESSAGE STRING
           STRLEN = LEN(RM_BUF(RM_LINES))
           DO WHILE (RM_BUF(RM_LINES)(STRLEN:STRLEN) .EQ. ' ')
             STRLEN = STRLEN - 1
           ENDDO
C   STOP LOOKING IF THE LAST CHARACTER READ WAS CLOSING DOUBLE-QUOTE
           IF (RM_BUF(RM_LINES)(STRLEN:STRLEN) .EQ. '"') EXIT
430      CONTINUE

C    PRINT ROOM DESCRIPTIONS IF ENABLED
         IF (PRINT_ROOMS .NE. 0) THEN
           IF (RM_LINES .GT. 1) THEN
             PRINT 406, 'RM #', I, ' HAS', RM_LINES, ' LINES'
           ENDIF
           PRINT 407,I,RM(I,1),RM(I,2),RM(I,3),RM(I,4),RM(I,5),RM_BUF(1)
         ENDIF

C   ONLY STORE THE FIRST LINE FOR NOW, PENDING GENERAL SOLUTION
         RS(I) = RM_BUF(1)

410    CONTINUE

C PRINT ACTIONS AFTER READING VOCAB WORDS

520    FORMAT (A, I3, A, A, A, A)
       IF (PPRINT_ACTIONS .NE. 0) THEN
         DO 500 I=1, CL+1
           VERB = C(I, 1) / 150
           NOUN = C(I, 1) - 150 * VERB
           IF (VERB .EQ. 0) THEN
             PRINT 230,'[',I,']  AUTO ', NOUN,'%'
           ELSE
             NOUN = NOUN + 1
             PRINT 520,'[',I,']  VERB ',VERBS(VERB),' NOUN ',NOUNS(NOUN)
           ENDIF

           DO 530 J=1, 5
             LL(J) = C(I,J+1) / 20
             W(J) = C(I, J+1) - 20 * LL(J)
530        CONTINUE
           DO 540 J=1, 5
             CALL TEST_PRINT(W(J), LL(J))
540        CONTINUE

           DO 550 J=0, 1
             AC(J*2+1) = C(I, J+7) / 150
             AC(J*2+2) = C(I, J+7) - 150 * AC(J*2+1)
550        CONTINUE
           DO 560 J=1, 4
             CALL ACTION_PRINT(AC(J))
560        CONTINUE

500    CONTINUE
       ENDIF

C   READ MESSAGES

605    FORMAT (A)
606    FORMAT (A, I3, A, I3, A)

       DO 600 I=1,ML+1
C   READ UP TO 5 LINES FOR ONE STRING
         DO 610 J=1,5
           MSG_BUF(J) = ""
610      CONTINUE
         DO 620 MSG_LINES=1,5
           READ (2, 605) MSG_BUF(MSG_LINES)
C   CHECK FOR ADDITIONAL LINES FOR THIS SAME MESSAGE STRING
           STRLEN = LEN(MSG_BUF(MSG_LINES))
           DO WHILE (MSG_BUF(MSG_LINES)(STRLEN:STRLEN) .EQ. ' ')
             STRLEN = STRLEN - 1
           ENDDO
C   STOP LOOKING IF THE LAST CHARACTER READ WAS CLOSING DOUBLE-QUOTE
           IF (MSG_BUF(MSG_LINES)(STRLEN:STRLEN) .EQ. '"') EXIT 
620      CONTINUE

C   DISPLAY MESSAGES
         IF (PRINT_MSG .EQ. 1) THEN
           PRINT 606, 'MSG #', I, ' HAS', MSG_LINES, ' LINES'
           DO 630 J=1,MSG_LINES
            PRINT 605, MSG_BUF(J)
630      CONTINUE
         ENDIF

C   ONLY STORE THE FIRST LINE FOR NOW, PENDING GENERAL SOLUTION
         MS(I) = MSG_BUF(1)

600    CONTINUE

C   READ ITEMS

       END

CCCCCCC

C PRINT OUT TEST ARGS
C
C CONDITIONS 0-14 USED BY ALL GAMES
C CONDITIONS 15+ NOT USED BY VERSIONS WRITTEN IN BASIC

       SUBROUTINE TEST_PRINT(TESTNUM, TESTARG)
       INTEGER TESTNUM, TESTARG

1010   FORMAT (A, I2, A)
       IF (TESTNUM .EQ. 0) THEN
         IF (TESTARG .NE. 0) THEN
           PRINT 1010, '  DATA ', TESTARG
         ENDIF
       ELSE IF (TESTNUM .EQ. 1) THEN
         PRINT 1010, '  IF ITEM(', TESTARG, ') IS HELD'
       ELSE IF (TESTNUM .EQ. 2) THEN
         PRINT 1010, '  IF ITEM(', TESTARG, ') IN ROOM WITH PLAYER'
       ELSE IF (TESTNUM .EQ. 3) THEN
         PRINT 1010, '  IF ITEM(', TESTARG, ') IS HELD OR IN ROOM'
       ELSE IF (TESTNUM .EQ. 4) THEN
         PRINT 1010, '  IF PLAYER IN ROOM #', TESTARG
       ELSE IF (TESTNUM .EQ. 5) THEN
         PRINT 1010, '  IF ITEM(', TESTARG, ') NOT IN ROOM WITH PLAYER'
       ELSE IF (TESTNUM .EQ. 6) THEN
         PRINT 1010, '  IF ITEM(', TESTARG, ') IS NOT HELD'
       ELSE IF (TESTNUM .EQ. 7) THEN
         PRINT 1010, '  IF PLAYER NOT IN ROOM #', TESTARG
       ELSE IF (TESTNUM .EQ. 8) THEN
         PRINT 1010, '  IF BIT(', TESTARG, ') SET'
       ELSE IF (TESTNUM .EQ. 9) THEN
         PRINT 1010, '  IF BIT(', TESTARG, ') CLEAR'
       ELSE IF (TESTNUM .EQ. 10) THEN
         PRINT 1010, '  IF ANYTHING HELD'
       ELSE IF (TESTNUM .EQ. 11) THEN
         PRINT 1010, '  IF NOTHING HELD', TESTARG
       ELSE IF (TESTNUM .EQ. 12) THEN
         PRINT 1010, '  IF ITEM(', TESTARG, ') NOT HELD AND NOT IN ROOM'
       ELSE IF (TESTNUM .EQ. 13) THEN
         PRINT 1010, '  IF ITEM(', TESTARG, ') EXISTS'
       ELSE IF (TESTNUM .EQ. 14) THEN
         PRINT 1010, '  IF ITEM(', TESTARG, ') DOES NOT EXIST'
       ELSE IF (TESTNUM .EQ. 15) THEN
         PRINT 1010, '  IF COUNTER <= ', TESTARG
       ELSE IF (TESTNUM .EQ. 16) THEN
         PRINT 1010, '  IF COUNTER >= ', TESTARG
       ELSE IF (TESTNUM .EQ. 17) THEN
         PRINT 1010, '  IF ITEM(', TESTARG, ') IN INITIAL ROOM'
       ELSE IF (TESTNUM .EQ. 18) THEN
         PRINT 1010, '  IF ITEM(', TESTARG, ') NOT IN INITIAL ROOM' 
       ELSE IF (TESTNUM .EQ. 19) THEN
         PRINT 1010, '  IF COUNTER NUM IS ', TESTARG
       ELSE
         PRINT 1010, 'UNKNOWN TEST', TESTNUM
       ENDIF

       RETURN

       END

C PRINT ACTIONS
C
C ACTIONS 51-72 USED BY ALL GAMES
C ACTIONS 72+ NOT USED BY VERSIONS WRITTEN IN BASIC
C ACTIONS 64 AND 76 HAVE IDENTICAL RESULTS

       SUBROUTINE ACTION_PRINT(ACTIONNUM)
       INTEGER ACTIONNUM

2010   FORMAT (A, I3, A)

C      PRINT 2010, '  --- AP ', ACTIONNUM

       IF (ACTIONNUM .EQ. 0) THEN
         PRINT 2010, '  0'
       ELSE IF (ACTIONNUM .GT. 0 .AND. ACTIONNUM .LE. 51) THEN
         PRINT 2010, '  THEN PRINT MSG #', ACTIONNUM - 1
       ELSE IF (ACTIONNUM .EQ. 52) THEN
         PRINT 2010, '  THEN GET ITEM <DATA>'
       ELSE IF (ACTIONNUM .EQ. 53) THEN
         PRINT 2010, '  THEN DROP ITEM <DATA>'
       ELSE IF (ACTIONNUM .EQ. 54 .OR. ACTIONNUM .EQ. 59) THEN
         PRINT 2010, '  THEN MOVE ITEM <DATA> TO CURRENT ROOM'
       ELSE IF (ACTIONNUM .EQ. 55) THEN
         PRINT 2010, '  THEN DESTROY ITEM <DATA>'
       ELSE IF (ACTIONNUM .EQ. 56) THEN
         PRINT 2010, '  THEN SET DARKFLAG'
       ELSE IF (ACTIONNUM .EQ. 57) THEN
         PRINT 2010, '  THEN CLEAR DARKFLAG'
       ELSE IF (ACTIONNUM .EQ. 58) THEN
         PRINT 2010, '  THEN SET BIT #<DATA>'
       ELSE IF (ACTIONNUM .EQ. 59) THEN
         PRINT 2010, '  THEN #59'
       ELSE IF (ACTIONNUM .EQ. 60) THEN
         PRINT 2010, '  THEN CLEAR BIT #<DATA>'
       ELSE IF (ACTIONNUM .EQ. 61) THEN
         PRINT 2010, '  THEN KILL PLAYER'
       ELSE IF (ACTIONNUM .EQ. 62) THEN
         PRINT 2010, '  THEN MOVE ITEM <DATA1> TO ROOM #<DATA2>'
       ELSE IF (ACTIONNUM .EQ. 63) THEN
         PRINT 2010, '  THEN END GAME'
       ELSE IF (ACTIONNUM .EQ. 64) THEN
         PRINT 2010, '  THEN DESCRIBE CURRENT ROOM(64)'
       ELSE IF (ACTIONNUM .EQ. 65) THEN
         PRINT 2010, '  THEN SCORE'
       ELSE IF (ACTIONNUM .EQ. 66) THEN
         PRINT 2010, '  THEN PRINT INVENTORY'
       ELSE IF (ACTIONNUM .EQ. 67) THEN
         PRINT 2010, '  THEN SET BIT 0'
       ELSE IF (ACTIONNUM .EQ. 68) THEN
         PRINT 2010, '  THEN CLEAR BIT 0'
       ELSE IF (ACTIONNUM .EQ. 69) THEN
         PRINT 2010, '  THEN REFILL LAMP(?)'
       ELSE IF (ACTIONNUM .EQ. 70) THEN
         PRINT 2010, '  THEN CLEAR SCREEN'
       ELSE IF (ACTIONNUM .EQ. 71) THEN
         PRINT 2010, '  THEN SAVE GAME'
       ELSE IF (ACTIONNUM .EQ. 72) THEN
         PRINT 2010, '  THEN SWAP ITEM <DATA1> LOC AND ITEM <DATA2> LOC'
       ELSE IF (ACTIONNUM .EQ. 73) THEN
         PRINT 2010, '  THEN CONTINUE TO NEXT ACTION'
       ELSE IF (ACTIONNUM .EQ. 74) THEN
         PRINT 2010, '  THEN MOVE ITEM <DATA> TO PLAYER'
       ELSE IF (ACTIONNUM .EQ. 75) THEN
         PRINT 2010, '  THEN MOVE ITEM <DATA1> NEXT TO ITEM <DATA2>'
       ELSE IF (ACTIONNUM .EQ. 76) THEN
         PRINT 2010, '  THEN DESCRIBE CURRENT ROOM(76)'
       ELSE IF (ACTIONNUM .EQ. 77) THEN
         PRINT 2010, '  THEN DECREMENT CURRENT COUNTER'
       ELSE IF (ACTIONNUM .EQ. 78) THEN
         PRINT 2010, '  THEN PRINT CURRENT COUNTER'
       ELSE IF (ACTIONNUM .EQ. 79) THEN
         PRINT 2010, '  THEN SET CURRENT COUNTER TO <DATA>'
       ELSE IF (ACTIONNUM .EQ. 80) THEN
         PRINT 2010, '  THEN MOVE PLAYER TO ALT ROOM'
       ELSE IF (ACTIONNUM .EQ. 81) THEN
         PRINT 2010, '  THEN SAVE COUNTER AND SWITCH TO <DATA>'
       ELSE IF (ACTIONNUM .EQ. 82) THEN
         PRINT 2010, '  THEN INCREASE` COUNTER BY <DATA>'
       ELSE IF (ACTIONNUM .EQ. 83) THEN
         PRINT 2010, '  THEN REDUCE COUNTER BY <DATA>'
       ELSE IF (ACTIONNUM .EQ. 84) THEN
         PRINT 2010, '  THEN GET PRINT THE NOUN TYPED (NO NEWLINE)'
       ELSE IF (ACTIONNUM .EQ. 85) THEN
         PRINT 2010, '  THEN GET PRINT THE NOUN TYPED (W/NEWLINE)'
       ELSE IF (ACTIONNUM .EQ. 86) THEN
         PRINT 2010, '  THEN GET PRINT NEWLINE'
       ELSE IF (ACTIONNUM .EQ. 87) THEN
         PRINT 2010, '  THEN SWAP CURRENT LOC WITH ALT LOC <DATA>'
       ELSE IF (ACTIONNUM .EQ. 88) THEN
         PRINT 2010, '  THEN SLEEP 2 SECONDS'
       ELSE IF (ACTIONNUM .EQ. 89) THEN
         PRINT 2010, '  *THEN DRAW PICTURE <DATA>'
       ELSE IF (ACTIONNUM .GE. 90 .AND. ACTIONNUM .LE. 101) THEN
         PRINT 2010, '  *UNUSED ACTION #', ACTIONNUM
       ELSE IF (ACTIONNUM .GE. 102 .AND. ACTIONNUM .LE. 150 ) THEN
         PRINT 2010, '  THEN PRINT MSG #', ACTIONNUM - 51
       ELSE 
         PRINT 2010, '  *UNHANDLED ACTION #', ACTIONNUM
       ENDIF

       RETURN

       END

