function [today_pay, main_text, sub_text, left_text, right_text] = print_screen(trial)
global subj hist 
if trial == 1 
    today_pay = '100';     
    if subj.treatment == 1
        main_text = '於 3 星 期 後 ， 將 收 到 115 法 幣';
    else
        main_text = '於 3 星 期 後 ， 收 到 115 法 幣';
    end
    sub_text ='左上角代表「今天」為「於今天，收到 110 法幣」';
    left_text = '是'; right_text = '否';
elseif trial == 2
    today_pay = ''; main_text = '「於今天，收到 X 枚法幣」';
    sub_text ='每回合的 X 都會一樣';
    left_text = '是'; right_text = '否';
elseif trial == 3
    today_pay = ''; 
    if subj.treatment == 1
        main_text = '「於 Y 星期後，將收到 Z 枚法幣」';
    else
        main_text = '「於 Y 星期後，收到 Z 枚法幣」';
    end
    sub_text ='每回合的 Y 都會一樣';
    left_text = '是'; right_text = '否';
elseif trial == 4
    today_pay = ''; 
    if subj.treatment == 1
        main_text = '「於 Y 星期後，將收到 Z 枚法幣」';
    else
        main_text = '「於 Y 星期後，收到 Z 枚法幣」';
    end
    sub_text ='每回合的 Z 都會一樣';
    left_text = '是'; right_text = '否';
elseif trial == 5
    today_pay = ''; main_text = '電腦會隨機從 36 個回合中選出其中 1 個回合，';
    sub_text ='您的獎勵會根據您在該回合所做的決定來實現。';
    left_text = '是'; right_text = '否';
elseif trial == 6
    today_pay = ''; main_text = '36 個回合被抽到的機率都不相同。';
    sub_text ='';
    left_text = '是'; right_text = '否';
elseif trial == 7
    today_pay = ''; main_text = '法幣所兌換的獎勵，不論您選「今天」或「未來」';
    sub_text ='都會以匯款的方式支付給您。';
    left_text = '是'; right_text = '否';   
elseif ismember(trial,(8:46))
    today_pay = num2str(hist.today_pay(trial));
    if subj.treatment == 1
        main_text = ['於 ' num2str(hist.weeks_delayed(trial)) ' 星 期 後 ， 將 收 到 ' num2str(hist.future_pay(trial)) ' 法 幣'];
    else
        main_text = ['於 ' num2str(hist.weeks_delayed(trial)) ' 星 期 後 ， 收 到 ' num2str(hist.future_pay(trial)) ' 法 幣'];
    end
    sub_text ='';
    if hist.left_is_future(trial)==1
        left_text = '未來'; right_text = '今天';
    else
        left_text = '今天'; right_text = '未來';
    end
elseif trial == 47
    today_pay = ''; main_text = '「於今天，收到 X 枚法幣」';
    sub_text ='與上一個階段的 X 相同';
    left_text = '是'; right_text = '否'; 
elseif trial == 48
    today_pay = ''; main_text = '這階段的選擇，';
    sub_text ='電腦不會從中隨機抽選 1 個回合來兌換成獎勵';
    left_text = '是'; right_text = '否'; 
elseif ismember(trial,(49:84))
    today_pay = num2str(hist.today_pay(trial));
    if subj.treatment == 1
        main_text = ['於 ' num2str(hist.weeks_delayed(trial)) ' 星 期 後 ， 將 收 到 ' num2str(hist.future_pay(trial)) ' 法 幣'];
    else
        main_text = ['於 ' num2str(hist.weeks_delayed(trial)) ' 星 期 後 ， 收 到 ' num2str(hist.future_pay(trial)) ' 法 幣'];
    end
    sub_text ='';
    if hist.left_is_future(trial)==1
        left_text = '未來'; right_text = '今天';
    else
        left_text = '今天'; right_text = '未來';
    end  
end

end

