#!/bin/bash
questions_from_input() {
  if [[ -n "$current_term" ]]; then
    line_number=1
    input_file=$(cat)
    input_length="$(echo "$input_file" | sentencify | wc -l | sed 's/ //g')"
    while IFS= read -r line; do
      if [[ $line == "" ]] || [[ $line == " " ]]; then
        continue
      else
        while true ; do
          [[ $prev_line ]] && line="${prev_line}${line}" && prev_line=
          [[ -n $1 ]] && line_start="$1" || line_start=1
          [[ $line_number -lt $line_start ]] && break
          percent=$((line_number * 100 / input_length))
          printf "\033c"
          if [[ -n $match ]]; then 
            if [[ $(echo $line | grep "$match") != "" ]]; then
              echo "Match \"$match\" found!" 
              echo "$line"
              unset match
            else
              break
            fi
          else
            echo "$line"
          fi
          echo "${BLACK_FG}${GREY_BG}line $line_number of $input_length ${GOLD_BG} ${percent}% ${RED_BG} "$(pwd | sed 's/.*\///g')" ${GREEN_BG} ${current_term} ${BLUE_BG} ❓ ${NC}"
          read -n1 -r -s input <&3
          case $input in
            a)
              read -p "Enter question here: " question <&3
              add_question "$question"
              sleep 1
              ;;
            b)
              if [[ $line_number -gt 1 ]]; then
                echo "$input_file" | questions_from_input $(( line_number - 1 ))
                break 2
              else
                echo "Cannot go back."
                sleep 0.5
              fi
              ;;
            c)
              chat_flippity <&3 #see flippity_prompt for overridden method
              sleep 0.75
              ;;
            e)
              read -p "bash $ " commands <&3
              if [[ $commands ]]; then
                eval "$commands"
                read -s -n1 -p "Type any key to continue" any_key <&3
              else
                echo "no command was entered"
                sleep 0.5
              fi
              ;;
            f)
              flashcards
              sleep 1
              ;;
            g)
              read -p "What do you want to look up?: " search <&3
              if [[ -n $search ]]; then
                echo "$search" | pbcopy
                google "$search"
              else
                echo "invalid search request"
                sleep 0.5
              fi
              ;;
            G)
              questions=()
              index=0
              while read question; do
                questions+=("$question");
                echo "$index - $question"
                (( index++ ))
              done <"Terms/$current_term/questions"
              read -p "please choose which of the above questions to google and copy to clipboard: " q_ind <&3
              if [[ -n $q_ind ]] && [[ ! "$q_ind" =~ [a-zA-Z] ]] && [[ -n ${questions[$q_ind]} ]]; then
                search="${questions[$q_ind]}"
                if [[ -n $search ]]; then
                  echo "$search" | pbcopy
                  google "$search"
                else
                  echo "invalid search request"
                  sleep 0.5
                fi
              else
                echo "Invalid question index."
                sleep 0.5
              fi
              ;;
            h)
              help_log="COMMAND HELP${NL}"
              help_log+="a = [a]dd a question to current term's questions file${NL}"
              help_log+="b = go [b]ack 1 input line${NL}" 
              help_log+="c = use [c]hat flippity program to generate a question for chatGPT (note - this depends on chat_flippity.sh file)${NL}" 
              help_log+="e = [e]valuate string as though typing on command line${NL}" 
              help_log+="f = [f]lashcards (for becoming more familiar with recently answered questions)${NL}" 
              help_log+="g = [g]oogle user input${NL}" 
              help_log+="G = [G]oogle one of current term's questions${NL}"
              help_log+="h = display qfi command [h]elp${NL}"
              help_log+="j = [j]ump to input line by number${NL}" 
              help_log+="k = open lin[k] by index from link file in new google tab${NL}" 
              help_log+="l = open [l]ist menu for questions, answers, statements, terms, libraries, sections, etc${NL}" 
              help_log+="m = go to book[m]ark${NL}" 
              help_log+="n = [n]ext input line${NL}" 
              help_log+="N = combi[N]e current line with next line and show as one line${NL}"
              help_log+="o = view [o]riginal line (no combined inputs)${NL}"
              help_log+="p = a[p]pend current line to research.txt${NL}" 
              help_log+="q = [q]uit qfi${NL}" 
              help_log+="s = [s]ection hopper${NL}" 
              help_log+="t = list and change current [t]erm${NL}" 
              help_log+="v = [v]im into questions, answers, research, or links${NL}"
              help_log+="w = ans[w]er one of the current term's questions${NL}"
              help_log+="W = ans[W]er one of the current term's unanswered questions${NL}" 
              help_log+="y = list all libraries and change current librar[y]${NL}" 
              help_log+="z = append current term to selected term [z]${NL}"
              help_log+="0 = go to beginning of input lines (works like vim's [0])${NL}"
              help_log+="# = hotkey for l[#], which lists basic question, answer, statement, and term stats${NL}" 
              help_log+="$ = go to end of input lines (works like vim's [$])${NL}" 
              help_log+="^ = google current input line and copy it to clipboard [^]${NL}" 
              help_log+="& = copy current input line to clipboard [&]${NL}" 
              help_log+="[ = google first unanswered question${NL}"
              help_log+="] = google last unanswered question${NL}"
              help_log+="{ = google first question (whether answered or unanswered)${NL}"
              help_log+="} = google last question(whether answered or unanswered)${NL}"
              help_log+=", = answer first unanswered question[.]${NL}"
              help_log+=". = answer last unanswered question [,]${NL}"
              help_log+="< = answer first question (whether answered or not) [<]${NL}"
              help_log+="> = answer last question (whether answered or not) [>]${NL}"
              help_log+="/ = search for a string in input lines (from current location, works like vim's [/])${NL}"
              help_log+="? = search for a string in statements (same as gz) [?]"
              echo "$help_log" | more -P "q to exit"
              ;;
            j)
              read -p "Jump to which line number? " user_line_start <&3
              if [[ $user_line_start -gt $input_length ]]; then
                echo "Sorry, there are only $input_length lines in total. Please jump to a smaller number."
                sleep 1
              elif [[ ! $user_line_start =~ [0-9] ]]; then
                echo "Please enter a valid line number."
                sleep 1
              else
                echo "$input_file" | questions_from_input "$user_line_start"
                break 2
              fi
              ;;
            k)
              list_of_links=()
              i=0
              while read link; do
                link_name=$(echo "$link" | sed 's/\(.*\): .*/\1/')
                relevant_link=$(echo "$link" | sed 's/.*: \(.*\)/\1/')
                list_of_links+=("$relevant_link")
                echo "$i - $link_name"
                (( i++ ))
              done < links
              read -p "Type the index of the link you want to open: " link_index <&3
              if [[ "$link_index" ]] && [[ $link_index -lt "$i" ]] && [[ $link_index -ge 0 ]]; then
                if [[ $(grep "${list_of_links[$link_index]}" links) != "" ]]; then 
                  echo "Going to link ${list_of_links[$link_index]}"
                  open "${list_of_links[$link_index]}"
                else
                  echo "Link name not found"
                  sleep 0.5
                fi
              else
                echo "Invalid link index"
                sleep 0.5
              fi
              ;;
            l)
              read -s -n1 -p "What would you like to list?"$'\n'"a/A - answers, l/L - answers, questions, and statements, q/Q - questions, r - relevant answers (to current line), s - sections, t - terms, u/U - unanswered, y - libraries, z/Z - statements, # - numbers. lowercase = current term; UPPERCASE = ALL terms in library."$'\n' list_op <&3
              case $list_op in 
              a)
                list answers
                ;;
              A)
                list answers all
                ;;
              l)
                list
                ;;
              L)
                list all
                ;;
              r)
                tput cup 2 0
                tput ed
                echo "$line ..." | get_statement_from_answer
                while read answer; do
                  if [[ "$answer" =~ "$line" ]]; then
                    echo -n "-"
                    echo "$answer" | sed "s/$line \(.*\)/\1/"
                  fi
                done < "Terms/$current_term/answers"
                ;;
              q)
                list questions
                ;;
              Q)
                list questions all
                ;;
              s)
                cat research.txt | sentencify | grep -nE "^[A-Z ]+$"
                ;;
              t)
                list_terms
                ;;
              u)
                list_unanswered_questions
                ;;
              U)
                list_unanswered_questions_all
                ;;
              y)
                list_libraries
                ;;
              z)
                list statements
                ;;
              Z)
                list statements all
                ;;
              \#)
                list_numbers
                ;;
              *)
                echo "Input not recognized. Please refer to the prompt for commands."
                sleep 1
                continue
                ;;
              esac
              echo ""
              press_any_key_to_escape <&3
              ;;
            m)
              match="BOOKMARK"
              break
              ;;
            n | "")
              break;
              ;;
            N)
              prev_line="$line${NL}"
              break;
              ;;
            o)
              prev_line=
              echo "$input_file" | questions_from_input "$line_number"
              break 2
              ;;
            p)
              if [[ $(grep "$line" research.txt) != "" ]]; then
                echo "❌ Line already exists in research.txt"
                sleep 0.5
              else
                echo "$line" >>research.txt
                echo "✅ Line added to research.txt"
                sleep 0.5
              fi
              ;;
            q)
              break 2
              ;;
            s)
              sections=()
              index=0
              while read section; do
                section_line=$(echo "$section" | sed 's/\(.*\):.*/\1/')
                section_display=$(echo "$section" | sed 's/.*\:\(.*\)/\1/')
                sections+=("$section_line")
                echo "$index - $section_display"
                (( index++ ))
              done < <(echo "$input_file" | sentencify | grep -nE "^[A-Z ]*$")
              read -p "Please choose which of the above sections you would like to jump to: " s_ind <&3
              if [[ $s_ind =~ [0-9] ]] && [[ $s_ind -lt "${#sections[@]}" ]]; then
                echo "$input_file" | questions_from_input "${sections[$s_ind]}"
                break 2
              else
                echo "Invalid section index."
                sleep 0.5
              fi
              ;;
            t)
              list_terms
              echo
              read -p "Change term $current_term to: " new_term <&3
              change_term "$new_term"
              sleep 0.75
              ;;
            v)
              echo "a = current term's answers"
              echo "l = links"
              echo "q = current term's questions"
              echo "r = research.txt"
              read -n1 -p "Which of the above would you like to vim into? " vim_choice <&3
              exec 4<&3
              case $vim_choice in
                a)
                  eval vim_answers_current_term <&4
                ;;
                l)
                  eval vi links <&4
                ;;
                q)
                  eval vim_questions_current_term <&4
                ;;
                r)
                  eval vi research.txt <&4
                ;;
              esac
              exec 4<&-
              ;;
            w|W)
              questions=()
              index=0
              [[ $input == "W" ]] && echo "UNANSWERED:"
              while read question; do
                if [[ "$input" == "W" ]]; then
                  grep -q "$question" "Terms/$current_term/answers" && continue
                fi
                questions+=("$question");
                echo "$index - $question"
                (( index++ ))
              done <"Terms/$current_term/questions"
              if [[ ${#questions} -gt 0 ]]; then
                echo
                read -p "Please choose which of the above questions you would like to answer: " q_ind <&3
                if [[ -n $q_ind ]] && [[ ! "$q_ind" =~ [a-zA-Z] ]] && [[ -n ${questions[$q_ind]} ]]; then
                  tput cup 2 0
                  tput ed
                  echo "${questions[$q_ind]}"
                  if [[ "$(get_statement_from_answer "${questions[$q_ind]} ")" != "" ]]; then
                    question_prompt="$(get_statement_from_answer "${questions[$q_ind]} ") "
                  else
                    question_prompt="WARNING: Statement not set up for current question. "
                  fi
                  read -p "$question_prompt" answer <&3
                  add_answer "${questions[$q_ind]}" "$answer" 
                  sleep 0.5
                else
                  echo "Invalid question index."
                  sleep 0.5
                fi
              else
                [[ $input == 'w' ]] && echo "No questions found for $current_term." || echo "No unanswered questions found for $current_term."
                sleep 1
              fi
              ;;
            y)
              list_libraries
              echo
              read -p "which library do you want to change to? " library <&3
              if [[ -d ../$library ]]; then
                change_library $library
                sleep 0.5
              else
                echo "Invalid library name."
                sleep 0.5
              fi
              ;;
            z)
              list_terms
              read -p "Which term would you like to append $current_term to?: " term_to_append <&3
              append_term "$term_to_append"
              sleep 0.75
              ;;
            Z)
              statements=$(statements_from_answers <&3)
              echo "${statements}${NL}"
              press_any_key_to_escape <&3
              ;;
            0)
              echo "$input_file" | questions_from_input
              break 2;
              ;;
            \#)
              list_numbers
              echo
              press_any_key_to_escape <&3
              ;;
            $)
              echo "$input_file" | questions_from_input "$input_length"
              break 2
              ;;
            ^)
              if [[ -n $line ]]; then
                search_line=$(echo "$line" | sed 's/UNANSWERED: //')
                echo $search_line | pbcopy
                google "$search_line"
              fi
              ;;
            \&)
              if [[ -n $line ]]; then
                line_to_copy=$(echo "$line" | sed 's/UNANSWERED: //')
                echo $line_to_copy | pbcopy
                echo "line copied to clipboard"
                sleep 0.5
              fi
              ;;
            \[)
              while read question; do
                if [[ $(grep "$question" "Terms/$current_term/answers") == "" ]]; then
                  first_unanswered_question=("$question");
                  break
                fi
              done <"Terms/$current_term/questions"
              if [[ "$first_unanswered_question" ]]; then
                echo "$first_unanswered_question" | pbcopy
                google "$first_unanswered_question"
                echo "copied and googled \"$first_unanswered_question\""
              else
                echo "No unanswered question exists, so nothing was searched or copied to clipboard"
              fi
              sleep 0.75
              ;;
            \])
              last_unanswered_question=""
              while read question; do
                if [[ $(grep "$question" "Terms/$current_term/answers") == "" ]]; then
                  last_unanswered_question=("$question");
                  break
                fi
              done < <(tail -r "Terms/$current_term/questions")
              if [[ "$last_unanswered_question" ]]; then
                echo "$last_unanswered_question" | pbcopy
                google "$last_unanswered_question"
                echo "copied and googled \"$last_unanswered_question\""
              else
                echo "No unanswered question exists, so nothing was searched or copied to clipboard"
              fi
              sleep 0.75
              ;;
            {)
              first_question=$(head -1 "Terms/$current_term/questions")
              if [[ "$first_question" ]]; then
                echo "$first_question" | pbcopy
                google "$first_question"
                echo "copied and googled \"$first_question\""
              else
                echo "No question exists, so nothing was searched or copied to clipboard"
              fi
              sleep 0.75
              ;;
            \})
              last_question=$(tail -1 "Terms/$current_term/questions")
              if [[ "$last_question" ]]; then
                echo "$last_question" | pbcopy
                google "$last_question"
                echo "copied and googled \"$last_question\""
              else
                echo "No question exists, so nothing was searched or copied to clipboard"
              fi
              sleep 0.75
              ;;
            ,)
              first_unanswered_question=""
              while read question; do
                if [[ $(grep "$question" "Terms/$current_term/answers") == "" ]]; then
                  first_unanswered_question=("$question");
                  break
                fi
              done <"Terms/$current_term/questions"
              if [[ -n "$first_unanswered_question" ]]; then 
                echo "$first_unanswered_question"
                if [[ "$(get_statement_from_answer "$first_unanswered_question")" != "" ]]; then
                  question_prompt="$(get_statement_from_answer "$first_unanswered_question ") "
                else
                  question_prompt="WARNING: Statement not set up for current question. "
                fi
                read -p "$question_prompt" answer <&3
                add_answer "$first_unanswered_question" "$answer" 
              else
                echo "No unanswered question exists"
              fi
              sleep 0.5
              ;;
            \.)
              last_unanswered_question=""
              while read question; do
                if [[ $(grep "$question" "Terms/$current_term/answers") == "" ]]; then
                  last_unanswered_question=("$question");
                  break
                fi
              done < <(tail -r "Terms/$current_term/questions")
              if [[ -n "$last_unanswered_question" ]]; then 
                echo "$last_unanswered_question"
                if [[ "$(get_statement_from_answer "$last_unanswered_question")" != "" ]]; then
                  question_prompt="$(get_statement_from_answer "$last_unanswered_question ") "
                else
                  question_prompt="WARNING: Statement not set up for current question. "
                fi
                read -p "$question_prompt" answer <&3
                add_answer "$last_unanswered_question" "$answer" 
              else
                echo "No unanswered question exists"
              fi
              sleep 0.5
              ;;
            \<)
              first_question=$(cat Terms/$current_term/questions | head -1)
              if [[ "$first_question" ]]; then 
                echo "$first_question"
                if [[ "$(get_statement_from_answer "$first_question")" != "" ]]; then
                  question_prompt="$(get_statement_from_answer "$first_question ") "
                else
                  question_prompt="WARNING: Statement not set up for current question. "
                fi
                read -p "$question_prompt" answer <&3
                add_answer "$first_question" "$answer" 
              else
                echo "No unanswered question exists"
              fi
              sleep 0.5
              ;;
            \>)
              last_question=$(cat Terms/$current_term/questions | tail -1)
              if [[ "$last_question" ]]; then 
                echo "$last_question"
                if [[ "$(get_statement_from_answer "$last_question")" != "" ]]; then
                  question_prompt="$(get_statement_from_answer "$last_question ") "
                else
                  question_prompt="WARNING: Statement not set up for current question. "
                fi
                read -p "$question_prompt" answer <&3
                add_answer "$last_question" "$answer" 
              else
                echo "No unanswered question exists"
              fi
              sleep 0.5
              ;;
            /)
              read -p "Enter search target: " target <&3
              if [[ -n "$target" ]]; then
                match="$target"
                break
              else
                echo "Invalid target"
                sleep 0.5
              fi
              ;;
            \?)
              read -p "gz " target <&3
              grep_statements_case_insensitive "$target"
              press_any_key_to_escape <&3
              ;;
            *)
              echo "Sorry, \"$input\" command not recognized."
              sleep 0.5
              ;;
          esac
        done
      fi
      line_number=$(($line_number + 1))
    done < <(echo "$input_file" | sentencify)
  else
    echo "You have not yet defined a current term. Please do so with change_term, then try again."
  fi
}
