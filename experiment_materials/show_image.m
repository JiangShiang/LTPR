function show_image = show_image(type, page_num, correctness)
global wPtr subj

if type == 1 % instructions
    if subj.treatment == 1
        image = imread(['treatment_instructions\P (' num2str(page_num) ').png']);
    else
        image = imread(['control_instructions\P (' num2str(page_num) ').png']);
    end
elseif type == 0 % quizess
    if subj.treatment == 1
        if correctness
            image = imread(['treatment_instructions\Q (' num2str(page_num) ')_c.png']);
        else % wrong
            image = imread(['treatment_instructions\Q (' num2str(page_num) ')_w.png']);
        end
    else % control group
        if correctness
            image = imread(['control_instructions\Q (' num2str(page_num) ')_c.png']);
        else
            image = imread(['control_instructions\Q (' num2str(page_num) ')_w.png']);
        end
    end
end

texture = Screen('MakeTexture', wPtr, image);
Screen('DrawTexture', wPtr, texture);
Screen('Flip',wPtr);

end

