clc;
close all;
clear all;
N=1e4;
N_rf=4;                         %��վ����Ƶ��·��
K=4;
L=3;
SNR_db = 10;              %����ȵ�����
SNR = 10.^(SNR_db./10);
Ms= [20;40;60;80;100];
rate_ben = zeros(length(Ms), 1);
rate_opt = zeros(length(Ms), 1);
rate_gm = zeros(length(Ms), 1);
rate_beam=zeros(length(Ms), 1);
rate_ggm = zeros(length(Ms), 1);  
phase=cell(1,K);
phase_lh=cell(1,K);
aaa=cell(1,K);
fai=zeros(K,1);  %��������Ӧ����λ
for Loop = 1:length(Ms)
    M = Ms(Loop, 1);
    for Loop_1 = 1 : N %ѭ������.
        co1=M;
        for s=1:K
            phase{1,s}=2*pi*rand(L,1);%�źŽ�����λ����
            phase_lh{1,s} = round(phase{1,s} / pi * M) / M * pi;
            aaa{1,s}=1/sqrt(2)*(randn(L,1)+1j*randn(L,1));%·��������ϸ���˹
        end
        H=zeros(M,K);
        jz=zeros(K,1);
        for kk=1:K
            % h1�ŵ����ԵĽ���-----hkk
            h1=zeros(M,1);
            for ss=1:L
                xiangwei_1=sin(phase{1,kk}(ss,1));%h1����λ
                zengyi_1=aaa{1,kk}(ss,1);       %h1������
                xiangYing_1=(exp(1j * pi * (0:1:M-1) * xiangwei_1)/sqrt(M))'; %������Ӧ
                h1=h1+sqrt(M/L)*(zengyi_1* xiangYing_1);   %h1�ŵ�����
                jz(kk)=jz(kk)+abs(aaa{1,kk}(ss,1));
            end
            jz(kk)=jz(kk)/L;
            H(:,kk)=h1;
            b1=abs(aaa{1,kk}(:,1));
            [~ ,i1]=max(b1);           %�ҳ�h1�������
            fai(kk,1)=phase{1,kk}(i1,1);     %���·�������Ӧ����λ
        end
        %%%%%%�㷨����
        Wrf=zeros(M,K);
        for kk = 1 : K
            %%%%%%%%%%   rf ��kk�е����
            m11=zeros(L,1);  %�������Сֵ
            for ll = 1 : L
                dd11=zeros(K-1,1); %��ʾ����
                cishu = 0;
                for ii=1:K
                    if abs(aaa{1,kk}(ll,1))<jz(kk)
                        continue;
                    else
                        if ii==kk
                            continue;
                        else
                            cishu = cishu + 1;
                            dd11(cishu,1)=abs(sin(phase_lh{1,kk}(ll,1))-sin(fai(ii,1)));    %�õ�3*1��������
                        end
                    end
                end
                m11(ll,1)=min(dd11);
            end
            [~,n1_rf]=max(m11);
            rf1=(exp(1j * pi * (0:1:M-1) *sin(phase_lh{1,kk}(n1_rf,1)))/sqrt(M))';
            Wrf(:,kk)=rf1;
        end
        Hx=Wrf'*H;
        Wbb=Hx/(Hx'*Hx+eye(K));
        HH=Wrf*Wbb;
        %%%%%%%%%%%%%%%
        rao = zeros(K, 1);
        power = zeros(K, 1);
        zao = zeros(K, 1);
        for ii=1:K
            power(ii,1)=(abs(HH(:,ii)'*H(:,ii)))^2;
            for kk = 1 : K
                if ii == kk
                else
                    rao(ii,1)= rao(ii,1) + (abs(HH(:,ii)'*H(:,kk)))^2;
                end
            end
            zao(ii,1)=(norm(HH(:,ii),2))^2;
        end
        for ii=1:K
            rate_ben(Loop,1)=rate_ben(Loop,1)+log2(1+power(ii,1)/(rao(ii,1)+zao(ii,1)/SNR));
        end
         %%%%%%%%% gram�������㷨  δ������
        U=zeros(M,K);
        W_gm=zeros(M,K);
        for kk=1:K
            U(:,kk)=H(:,kk);
            for ii=1:kk-1
                p=U(:,ii)'*H(:,kk);
                U(:,kk)=U(:,kk)-p*U(:,ii)/Q;
            end
            Q=U(:,kk)'*U(:,kk);
            for tt=1:M     
                W_gm(tt,kk)=1/sqrt(M)*U(tt,kk)/(sqrt(U(tt,kk)*conj(U(tt,kk))));
            end
        end
        Hg=W_gm'*H;
        Wbb_gm=Hg/(Hg'*Hg+eye(K));
        H_gm=W_gm*Wbb_gm;
        p_gm=zeros(K,1);
        rao_gm=zeros(K,1);
        for ii=1:K
            p_gm(ii,1)=(abs((H_gm(:,ii))'*H(:,ii)))^2;
            for kk = 1 : K
                if ii == kk
                else
                    rao_gm(ii,1)=rao_gm(ii,1)+(abs((H_gm(:,ii))'*H(:,kk)))^2;
                end
            end
            rate_gm(Loop, 1)=rate_gm(Loop, 1)+log2(1+p_gm(ii,1)/(rao_gm(ii,1)+zao(ii,1)/SNR));
        end
        %%%%%%%%% gram�������㷨  ������
        F=zeros(M,co1);
        m=zeros(M,1);
        W_ggm=zeros(M,K);
        for kk=1:co1
            F(:,kk)=(exp(1j * pi * (0:1:M-1) * sin(pi*(kk-1)/co1))/sqrt(M))';
        end
        for kk=1:K
            for ii=1:co1
                m(ii)=abs(F(:,ii)'*W_gm(:,kk));
            end
            [~,po]=max(m);
            W_ggm(:,kk)=F(:,po);
        end     
        Hgg=W_ggm'*H;
        Wbb_ggm=Hgg/(Hgg'*Hgg+eye(K));
        H_ggm=W_ggm*Wbb_ggm;
        p_ggm=zeros(K,1);
        rao_ggm=zeros(K,1);
        for ii=1:K
            p_ggm(ii,1)=(abs((H_ggm(:,ii))'*H(:,ii)))^2;
            for kk = 1 : K
                if ii == kk
                else
                    rao_ggm(ii,1)=rao_ggm(ii,1)+(abs((H_ggm(:,ii))'*H(:,kk)))^2;
                end
            end
            rate_ggm(Loop, 1)=rate_ggm(Loop, 1)+log2(1+p_ggm(ii,1)/(rao_ggm(ii,1)+zao(ii,1)/SNR));
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%  ȫ����
        W_opt = ((H'*H)\H')';
        p_opt = zeros(K, 1);
        rao_opt = zeros(K, 1);
        for ii=1:K
            p_opt(ii,1)=(abs((W_opt(:,ii))'*H(:,ii)))^2;
            for kk = 1 : K
                if ii == kk
                else
                    rao_opt(ii,1)=rao_opt(ii,1)+(abs((W_opt(:,ii))'*H(:,kk)))^2;
                end
            end
            rate_opt(Loop,1)=rate_opt(Loop,1)+log2(1+p_opt(ii,1)/(rao_opt(ii,1)+zao(ii,1)/SNR));
        end
        %%%%%%%%%%%%%%���û����޷���
        W_beam=zeros(M,K);
        ddd=zeros(co1,1);
        for kk=1:K
            for ll=1:co1
                ddd(ll,1)=abs(F(:,ll)'*H(:,kk));
            end
            [~,tt]=max(ddd);
            W_beam(:,kk)=F(:,tt);
        end
        Hb=W_beam'*H;
        Wbb_beam=Hb/(Hb'*Hb+eye(K));
        H_beam=W_beam*Wbb_beam;
        p_beam=zeros(K,1);
        rao_beam=zeros(K,1);
        for ii=1:K
            p_beam(ii,1)=(abs((H_beam(:,ii))'*H(:,ii)))^2;
            for kk = 1 : K
                if ii == kk
                else
                    rao_beam(ii,1)=rao_beam(ii,1)+(abs((H_beam(:,ii))'*H(:,kk)))^2;
                end
            end
            rate_beam(Loop,1)=rate_beam(Loop,1)+log2(1+p_beam(ii,1)/(rao_beam(ii,1)+zao(ii,1)/SNR));
        end
        disp([Loop, Loop_1])
    end
end
rate_ben = rate_ben / N;
rate_opt = rate_opt / N;
rate_gm = rate_gm/N;
rate_beam=rate_beam/N;
rate_ggm=rate_ggm/N;
plot(Ms,rate_opt,'--ko');
hold on
plot(Ms ,rate_gm,'--kd');
plot(Ms ,rate_ben,'-k*');
plot(Ms ,rate_ggm,'--k>');
plot(Ms,rate_beam,'--ks','Markersize', 12);
grid on
xlabel('��վ��������');
ylabel('������[bit/s/Hz]');
legend('ȫ����','ʩ����������[10]','��������㷨','ʩ��������������[10]','��������[9]');










