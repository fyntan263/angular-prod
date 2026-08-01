import { TestBed } from '@angular/core/testing';
import { App } from './app';

describe('App', () => {
  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [App],
    }).compileComponents();
  });

  it('should create the app', () => {
    const fixture = TestBed.createComponent(App);
    const app = fixture.componentInstance;
    expect(app).toBeTruthy();
  });

  it('should render title', async () => {
    const fixture = TestBed.createComponent(App);
    await fixture.whenStable();
    const compiled = fixture.nativeElement as HTMLElement;
    expect(compiled.querySelector('h1')?.textContent).toContain('Hello, angular-prod');
  });

  it('should increment the counter when the + button is clicked', async () => {
    const fixture = TestBed.createComponent(App);
    await fixture.whenStable();
    const compiled = fixture.nativeElement as HTMLElement;

    const incrementButton = Array.from(compiled.querySelectorAll('button')).find(
      (button) => button.textContent?.trim() === '+',
    );
    expect(incrementButton).toBeTruthy();

    incrementButton!.click();
    await fixture.whenStable();

    expect(compiled.querySelector('[data-testid="count"]')?.textContent).toContain('1');
  });
});
